# frozen_string_literal: true

module Yamlease
  # A task in a deployment phase, converted to a YAML step.
  class Task
    include Reporting

    attr_reader :display_name, :task_id

    def initialize(definition, job = nil, warnings = [])
      @definition = definition
      @job = job
      @warnings = warnings
      @display_name = definition['name']
      @task_id = definition['taskId']
    end

    def context
      "#{@job&.context || 'Task'}, task '#{display_name}'"
    end

    def major_version
      @definition['version'].to_s[/\A\d+/]
    end

    def yaml_name
      TaskDefinition.yaml_name(task_id, major_version)
    end

    # Inputs with a value, unchanged. $(var) macro syntax is valid in YAML
    # pipelines, so it is passed through as is.
    def inputs
      (@definition['inputs'] || {}).reject { |_, value| value.nil? || value == '' }
    end

    def condition
      condition = @definition['condition']
      return condition unless [nil, '', 'succeeded()'].include?(condition)

      'succeededOrFailed()' if @definition['alwaysRun']
    end

    # The step as a Hash, or nil if it cannot be converted.
    def to_h
      if @definition['definitionType'] == 'metaTask'
        return todo('left out because it is a task group; convert the group to a step template')
      end

      { 'task' => resolved_name, 'displayName' => display_name }.merge(options).compact
    end

    private

    def options
      {
        'enabled' => (false if @definition['enabled'] == false),
        'condition' => condition,
        'continueOnError' => (true if @definition['continueOnError']),
        'timeoutInMinutes' => Yamlease.positive(@definition['timeoutInMinutes']),
        'inputs' => Yamlease.presence(inputs)
      }
    end

    def resolved_name
      name, exact = TaskDefinition.lookup(task_id, major_version)
      unless name
        todo("task #{task_id} version #{@definition['version']} is not a built-in task " \
             '(probably a Marketplace extension); replace `Unknown` with its YAML name')
        return 'Unknown'
      end
      todo("version #{@definition['version']} is not in the task map, so #{name} was used") unless exact
      name
    end
  end
end
