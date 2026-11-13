# frozen_string_literal: true

require 'date'
require 'yaml'

module Yamlease
  # An exported release definition, converted to a YAML pipeline.
  class ReleasePipeline
    include Reporting

    # Messages about anything that could not be converted, filled in by #to_h.
    attr_reader :url, :warnings

    def initialize(filename = nil)
      raise ArgumentError, 'I need a release definition file to parse' if filename.nil?

      @warnings = []
      @pipeline = YAML.safe_load_file(filename, permitted_classes: [Date, Time])
      validate!
      @url = @pipeline['url']
    end

    def context
      'Pipeline'
    end

    def variables
      @pipeline['variables'] || {}
    end

    def variables_to_yaml
      super(variables) || {}
    end

    # Classic release "environments" become YAML stages, in the order they are
    # shown in the release editor.
    def stages
      @stages ||= begin
        taken = [BUILD_STAGE]
        (@pipeline['environments'] || [])
          .sort_by { |environment| environment['rank'].to_i }
          .map { |environment| Stage.new(environment, Yamlease.identifier(environment['name'], taken), @warnings) }
      end
    end

    def to_h
      @warnings.clear
      variables = Yamlease.presence(variables_to_yaml)
      warn_about_variable_groups(@pipeline['variableGroups'])
      warn_about_artifacts
      {
        'trigger' => ['main'], 'variables' => variables, 'pool' => { 'vmImage' => 'ubuntu-latest' },
        'stages' => [build_stage, *converted_stages]
      }.compact
    end

    def to_yaml
      body = to_h # populates warnings
      header = warnings.map { |message| "# TODO: #{message}\n" }.join
      header + YAML.dump(body).delete_prefix("---\n")
    end

    private

    def validate!
      if @pipeline.is_a?(Array)
        raise Error, 'This looks like the output of `az pipelines release definition list`. ' \
                     'Export a single definition with `az pipelines release definition show --id ID`.'
      end
      return if @pipeline.is_a?(Hash) && @pipeline.key?('environments')

      raise Error, 'This does not look like a release definition: it has no environments. ' \
                   'Export one with `az pipelines release definition show --id ID`.'
    end

    # Converts each stage, working out dependsOn from the release triggers. A
    # stage that is skipped passes its own dependencies on to its dependants.
    def converted_stages
      resolved = {}
      stages.filter_map do |stage|
        depends_on = dependencies(stage, resolved)
        converted = stage.to_h(depends_on)
        resolved[stage.name] = converted ? [stage.identifier] : depends_on
        converted
      end
    end

    def dependencies(stage, resolved)
      depends_on = stage.triggered_by.flat_map { |name| resolve(stage, name, resolved) }.uniq
      # An empty dependsOn would start the stage straight away, before the build.
      depends_on.empty? ? [BUILD_STAGE] : depends_on
    end

    def resolve(stage, name, resolved)
      return [BUILD_STAGE] if name == BUILD_STAGE
      return resolved[name] if resolved.key?(name)

      stage.todo("depends on '#{name}', which was not found before it")
      [stages.find { |other| other.name == name }&.identifier].compact
    end

    def warn_about_artifacts
      (@pipeline['artifacts'] || []).each do |artifact|
        source = artifact.dig('definitionReference', 'definition', 'name')
        @warnings << "Artifact '#{artifact['alias']}' (#{artifact['type']}#{", from #{source}" if source}): " \
                     'add it under `resources` and download it in the jobs that use it'
      end
    end

    def build_stage
      {
        'stage' => BUILD_STAGE,
        'jobs' => [{ 'job' => 'Build', 'steps' => [{ 'bash' => 'echo Build your application here' }] }]
      }
    end
  end
end
