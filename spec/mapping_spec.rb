# frozen_string_literal: true

require 'json'
require 'tempfile'
require_relative 'spec_helper'
require_relative '../lib/yamlease'

# How classic release features map onto the YAML pipeline. Fixture exports are
# used where they have the feature; small inline definitions cover the rest.
RSpec.describe 'Converting release features' do
  def convert(fixture)
    pipeline = Yamlease::ReleasePipeline.new(fixture_path(fixture))
    [pipeline.to_h, pipeline.warnings]
  end

  def convert_definition(definition)
    Tempfile.create(['definition', '.json']) do |file|
      file.write(JSON.generate(definition))
      file.flush
      pipeline = Yamlease::ReleasePipeline.new(file.path)
      [pipeline.to_h, pipeline.warnings]
    end
  end

  def task(overrides = {})
    {
      'name' => 'Run a script', 'taskId' => 'd9bafed4-0b18-4f58-968d-86655b4d2ce9', 'version' => '2.*',
      'enabled' => true, 'condition' => 'succeeded()', 'inputs' => { 'script' => 'echo hi' }
    }.merge(overrides)
  end

  def phase(tasks = [task], name: 'Agent job', type: 'agentBasedDeployment')
    { 'name' => name, 'phaseType' => type, 'workflowTasks' => tasks }
  end

  def environment(name, overrides = {})
    {
      'name' => name, 'rank' => 1,
      'conditions' => [{ 'conditionType' => 'event', 'name' => 'ReleaseStarted', 'value' => '' }],
      'deployPhases' => [phase]
    }.merge(overrides)
  end

  # A trigger that runs a stage after another one reaches the given status flags.
  def after(name, value = '4', type: 'environmentState')
    { 'conditionType' => type, 'name' => name, 'value' => value }
  end

  def convert_environments(*environments, **definition)
    convert_definition(definition.transform_keys(&:to_s).merge('environments' => environments))
  end

  def stage(pipeline, identifier)
    pipeline['stages'].find { |s| s['stage'] == identifier }
  end

  describe 'stages' do
    it 'turns stage names into identifiers and keeps the original as displayName' do
      pipeline, = convert('show.yml')
      expect(stage(pipeline, 'Stage_2')).to include('displayName' => 'Stage 2')
    end

    it 'makes the first stage depend on the build stage' do
      pipeline, = convert('random2.yml')
      expect(stage(pipeline, 'dev')['dependsOn']).to eq(['BuildThings'])
    end

    it 'passes the dependencies of a skipped stage on to the stages after it' do
      pipeline, warnings = convert('show.yml')
      expect(stage(pipeline, 'Stage_1')).to be_nil
      expect(stage(pipeline, 'Stage_2')['dependsOn']).to eq(['BuildThings'])
      expect(warnings).to include(a_string_matching(/Stage 'Stage 1': skipped/))
    end

    it 'depends on the stage named in an environment trigger' do
      pipeline, = convert_environments(environment('QA'),
                                       environment('Prod', 'rank' => 2, 'conditions' => [after('QA', type: 2)]))
      expect(stage(pipeline, 'Prod')['dependsOn']).to eq(['QA'])
    end

    it 'warns when a stage also runs after a failed or partially successful stage' do
      _, warnings = convert_environments(environment('QA'),
                                         environment('Prod', 'rank' => 2, 'conditions' => [after('QA', '132')]))
      expect(warnings).to include(a_string_matching(/Stage 'Prod': runs after 'QA'.*status flags 132/))
    end

    it 'warns about manually deployed stages and artifact filters' do
      pipeline, warnings = convert_environments(
        environment('Manual', 'conditions' => []),
        environment('Filtered', 'conditions' => [after('drop', '{}', type: 4)])
      )
      expect(stage(pipeline, 'Filtered')['dependsOn']).to eq(['BuildThings'])
      expect(warnings).to include(a_string_matching(/Stage 'Manual': was only deployed manually/),
                                  a_string_matching(/Stage 'Filtered': has an artifact filter on 'drop'/))
    end

    it 'warns about manual approvals and gates' do
      manual = { 'isAutomated' => false }
      _, warnings = convert_environments(
        environment('Prod', 'preDeployApprovals' => { 'approvals' => [manual, manual] },
                            'postDeploymentGates' => { 'gates' => [{ 'tasks' => [] }] })
      )
      expect(warnings).to include(a_string_matching(/2 pre-deployment approver/),
                                  a_string_matching(/postDeploymentGates/))
    end
  end

  describe 'jobs' do
    it 'runs jobs one after another, as classic deployment phases did' do
      pipeline, = convert('random2.yml')
      jobs = stage(pipeline, 'dev')['jobs']
      expect(jobs.map { |job| job['dependsOn'] })
        .to eq([nil, 'ProvisionInfrastructure', 'DeployUsingWebDeploy', 'RunTests'])
    end

    it 'runs agentless jobs on the server pool' do
      pipeline, = convert_environments(environment('QA', 'deployPhases' => [phase(name: 'Wait', type: 2)]))
      expect(stage(pipeline, 'QA')['jobs'].first['pool']).to eq('server')
    end

    it 'uses the hosted image the job ran on' do
      pipeline, = convert('random3.yml')
      expect(stage(pipeline, 'Stage_1')['jobs'].first['pool']).to eq('vmImage' => 'vs2017-win2016')
    end

    it 'warns about agent queues it cannot name' do
      _, warnings = convert('random2.yml')
      expect(warnings).to include(a_string_matching(/job 'Provision infrastructure': ran on agent queue ID 14/))
    end

    it 'warns about deployment group jobs' do
      _, warnings = convert_environments(environment('QA', 'deployPhases' => [phase(name: 'VMs', type: 4)]))
      expect(warnings).to include(a_string_matching(/job 'VMs': ran on a deployment group/))
    end
  end

  describe 'tasks' do
    it 'chooses the task name for the major version in use' do
      pipeline, = convert('random2.yml')
      tasks = stage(pipeline, 'dev')['jobs'].flat_map { |job| job['steps'] }.map { |step| step['task'] }
      expect(tasks).to include('DotNetCoreInstaller@0', 'AzureResourceGroupDeployment@2', 'AzureCLI@1')
    end

    it 'keeps disabled tasks disabled' do
      pipeline, = convert('random3.yml')
      step = stage(pipeline, 'Stage_1')['jobs'].first['steps'].find { |s| s['displayName'] == 'Command Line Script' }
      expect(step['enabled']).to be(false)
    end

    it 'carries over conditions, continueOnError and timeouts' do
      step = task('alwaysRun' => true, 'continueOnError' => true, 'timeoutInMinutes' => 5)
      pipeline, = convert_environments(environment('QA', 'deployPhases' => [phase([step], type: 1)]))
      expect(stage(pipeline, 'QA')['jobs'].first['steps'].first)
        .to include('condition' => 'succeededOrFailed()', 'continueOnError' => true, 'timeoutInMinutes' => 5)
    end

    it 'warns about tasks that are not built in' do
      pipeline, warnings = convert('random3.yml')
      expect(stage(pipeline, 'Stage_1')['jobs'].first['steps'].first['task']).to eq('Unknown')
      expect(warnings).to include(a_string_matching(/task 'PowerApps Tool Installer ': .*not a built-in task/))
    end

    it 'leaves out task groups with a warning' do
      group = task('name' => 'Shared steps', 'definitionType' => 'metaTask')
      _, warnings = convert_environments(environment('QA', 'deployPhases' => [phase([task, group])]))
      expect(warnings).to include(a_string_matching(/task 'Shared steps': left out because it is a task group/))
    end
  end

  describe 'variables and artifacts' do
    it 'leaves out secret variables with a warning' do
      pipeline, warnings = convert('random2.yml')
      expect(pipeline['variables']).not_to have_key('VSTSToken')
      expect(warnings).to include(a_string_matching(/secret variable 'VSTSToken'/))
    end

    it 'adds stage variables to the stage' do
      pipeline, = convert_environments(environment('QA', 'variables' => { 'Slot' => { 'value' => 'staging' } }))
      expect(stage(pipeline, 'QA')['variables']).to eq('Slot' => 'staging')
    end

    it 'warns about variable groups and artifacts' do
      _, warnings = convert_environments(environment('QA'), variableGroups: [7],
                                                            artifacts: [{ 'alias' => 'drop', 'type' => 'Build' }])
      expect(warnings).to include(a_string_matching(/variable group IDs 7/),
                                  a_string_matching(/Artifact 'drop' \(Build\)/))
    end
  end

  it 'rejects a file that is not a release definition' do
    expect { convert_definition('name' => 'not a release') }.to raise_error(Yamlease::Error, /no environments/)
  end
end
