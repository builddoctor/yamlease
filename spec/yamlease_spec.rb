# frozen_string_literal: true

require_relative 'spec_helper'
require_relative '../lib/yamlease'

PIPELINE_URL = 'https://vsrm.dev.azure.com/example-org/00000000-0000-0000-0000-000000000004/_apis/Release/definitions/1'

RSpec.describe Yamlease::ReleasePipeline do
  let(:rp) do
    Yamlease::ReleasePipeline.new(fixture_path('show.yml'))
  end

  it 'has a URL' do
    expect(rp.url).to eq(PIPELINE_URL)
  end

  it 'has multiple stages' do
    expect(rp.stages[1].name).to eq('Stage 2')
  end

  it 'will list all the jobs in a stage' do
    expect(rp.stages.first.jobs).to be_a(Array)
  end

  it 'will list all the tasks in a job' do
    expect(rp.stages[1].jobs.first.tasks.first.display_name).to eq('Deploy Azure App Service')
  end

  it 'will get the task IDs in a job' do
    expect(rp.stages[1].jobs.first.tasks.first.task_id).to eq('497d490f-eea7-4f2b-ab94-48d9c1acdcb1')
  end

  it 'should know how to parse a task' do
    expect(Yamlease::TaskDefinition.yaml_name('D9BAFED4-0B18-4F58-968D-86655B4D2CE9')).to eq('CmdLine@2')
  end

  it 'should return a good default when you fail to find a task' do
    expect(Yamlease::TaskDefinition.yaml_name('D9BAFED4-0B18-4F58-968D-HURRSDUDF')).to eq('Unknown')
  end

  it 'should get a list of tasks from a job' do
    expect(rp.stages[1].jobs.first.tasks.first).to be_a(Yamlease::Task)
  end

  it "should not give inputs that don't have a value" do
    expect(rp.stages[1].jobs.first.tasks.first.inputs.first).to eq(['AppSettings', '-RAILS_SERVE_STATIC_FILES true'])
  end

  it 'should have job names without spaces' do
    expect(rp.stages[1].jobs.first.name).to eq('RunOnAgent')
  end

  it 'leaves $(...) macro syntax alone, since YAML pipelines support it' do
    expect(rp.stages[1].jobs.first.tasks.first.inputs['PublishProfilePath'])
      .to eq('$(System.DefaultWorkingDirectory)/**/*.pubxml')
  end

  it 'does not rewrite shell command substitution in inline scripts' do
    expect(rp.stages[1].jobs.first.tasks.first.inputs['InlineScript'])
      .to include('eval "$(rbenv init -)"')
  end

  it 'returns the same inputs when called twice' do
    task = rp.stages[1].jobs.first.tasks.first
    first_call = task.inputs.to_a
    expect(task.inputs.to_a).to eq(first_call)
  end

  it 'picks the task version the release actually uses' do
    expect(rp.stages[1].jobs.first.tasks.first.yaml_name).to eq('AzureRmWebAppDeployment@4')
  end

  it 'should find variables' do
    expect(rp.variables['FooBar']['value']).to eq('baz')
  end

  it 'should convert variables to hashes for YAML pipelines' do
    expect(rp.variables_to_yaml).to eq({ 'FooBar' => 'baz' })
  end

  it "should throw an error if there's no args" do
    expect { Yamlease::ReleasePipeline.new }.to raise_error(ArgumentError)
  end
end
