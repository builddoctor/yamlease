# frozen_string_literal: true

module Yamlease
  # A deployment phase in a release environment, converted to a YAML job.
  class Job
    include Reporting

    attr_reader :display_name, :name

    def initialize(definition, stage, taken, warnings = [])
      @definition = definition
      @stage = stage
      @warnings = warnings
      @display_name = definition['name'].to_s
      @name = Yamlease.identifier(display_name, taken, camel_case: true)
    end

    def context
      "#{@stage.context}, job '#{display_name}'"
    end

    def phase_type
      Yamlease.enum(@definition['phaseType'], PHASE_TYPES)
    end

    def tasks
      (@definition['workflowTasks'] || []).map { |task| Task.new(task, self, @warnings) }
    end

    # The job as a Hash, or nil if it has nothing to run.
    def to_h(previous_job = nil)
      steps = self.steps
      return unless steps

      {
        'job' => name, 'displayName' => (display_name unless display_name == name),
        'dependsOn' => previous_job, 'pool' => pool, 'condition' => condition,
        'timeoutInMinutes' => Yamlease.positive(input['timeoutInMinutes']), 'steps' => steps
      }.compact
    end

    private

    def steps
      if phase_type == 'deploymentGates'
        return todo('skipped because gate phases have no YAML equivalent; use environment checks')
      end

      Yamlease.presence(tasks.filter_map(&:to_h)) || todo('skipped because it has no tasks')
    end

    def input
      @definition['deploymentInput'] || {}
    end

    def condition
      input['condition'] unless [nil, '', 'succeeded()'].include?(input['condition'])
    end

    def pool
      case phase_type
      when 'runOnServer' then 'server'
      when 'machineGroupBasedDeployment'
        todo('ran on a deployment group; convert it to a deployment job ' \
             'that targets an environment with virtual machine resources')
      else agent_pool
      end
    end

    def agent_pool
      image = input.dig('agentSpecification', 'identifier')
      return { 'vmImage' => image } if image
      return unless input['queueId']

      todo("ran on agent queue ID #{input['queueId']}; set `pool: name:` if that is not a Microsoft-hosted pool")
    end
  end
end
