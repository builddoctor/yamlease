# frozen_string_literal: true

module Yamlease
  # A classic release environment, converted to a YAML stage.
  class Stage
    include Reporting

    attr_reader :name, :identifier, :definition

    def initialize(definition, identifier, warnings = [])
      @definition = definition
      @identifier = identifier
      @warnings = warnings
      @name = definition['name']
    end

    def context
      "Stage '#{name}'"
    end

    def jobs
      taken = []
      (definition['deployPhases'] || []).map { |phase| Job.new(phase, self, taken, @warnings) }
    end

    def conditions
      (definition['conditions'] || []).map do |condition|
        condition.merge('conditionType' => Yamlease.enum(condition['conditionType'], CONDITION_TYPES))
      end
    end

    # Names of the stages this one waits for, as named in the classic release.
    def triggered_by
      if conditions.empty?
        todo('was only deployed manually; add an approval check to an environment ' \
             'and use a deployment job, or remove the stage from this pipeline')
        return [BUILD_STAGE]
      end
      conditions.filter_map { |condition| trigger(condition) }
    end

    # The stage as a Hash, or nil if it has nothing to run.
    def to_h(depends_on)
      jobs = chained_jobs
      return todo('skipped because it has no jobs with tasks') if jobs.empty?

      warn_about_approvals
      warn_about_gates
      warn_about_variable_groups(definition['variableGroups'])
      {
        'stage' => identifier, 'displayName' => (name unless name == identifier),
        'dependsOn' => depends_on, 'variables' => variables_to_yaml(definition['variables']), 'jobs' => jobs
      }.compact
    end

    private

    def trigger(condition)
      case condition['conditionType']
      when 'event' then BUILD_STAGE
      when 'environmentState' then after_stage(condition)
      when 'artifact'
        todo("has an artifact filter on '#{condition['name']}'; add an equivalent stage condition")
      end
    end

    def after_stage(condition)
      unless condition['value'].to_s == ENVIRONMENT_SUCCEEDED
        todo("runs after '#{condition['name']}' finishes with status flags #{condition['value']}, " \
             'not just success; add a condition on its result')
      end
      condition['name']
    end

    # Classic deployment phases run one after another; YAML jobs run in
    # parallel unless told otherwise, so chain each job to the one before.
    def chained_jobs
      jobs.each_with_object([]) do |job, done|
        converted = job.to_h(done.last&.fetch('job'))
        done << converted if converted
      end
    end

    def warn_about_approvals
      { 'pre' => 'preDeployApprovals', 'post' => 'postDeployApprovals' }.each do |kind, key|
        manual = (definition.dig(key, 'approvals') || []).count { |approval| !approval['isAutomated'] }
        next if manual.zero?

        todo("has #{manual} #{kind}-deployment approver(s); " \
             'add an approval check to an environment and use a deployment job')
      end
    end

    def warn_about_gates
      %w[preDeploymentGates postDeploymentGates].each do |key|
        todo("has #{key}; add equivalent checks to an environment") unless (definition.dig(key, 'gates') || []).empty?
      end
    end
  end
end
