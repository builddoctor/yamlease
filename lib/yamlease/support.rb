# frozen_string_literal: true

# Constants and helpers shared by the converters.
module Yamlease
  class Error < StandardError; end

  BUILD_STAGE = 'BuildThings'

  # The REST API returns some enums as numbers and the CLI as names.
  CONDITION_TYPES = { 1 => 'event', 2 => 'environmentState', 4 => 'artifact' }.freeze
  PHASE_TYPES = {
    1 => 'agentBasedDeployment', 2 => 'runOnServer',
    4 => 'machineGroupBasedDeployment', 8 => 'deploymentGates'
  }.freeze
  ENVIRONMENT_SUCCEEDED = '4'

  def self.enum(value, names)
    names.fetch(value, value).to_s
  end

  # Turns a display name into an identifier that is valid for a stage or job,
  # unique among those already in `taken`.
  def self.identifier(name, taken, camel_case: false)
    parts = name.to_s.split(/[^A-Za-z0-9_]+/).reject(&:empty?)
    base = camel_case ? parts.map { |part| part[0].upcase + part[1..] }.join : parts.join('_')
    base = "_#{base}" unless base.match?(/\A[A-Za-z_]/)
    candidate = base
    suffix = 1
    candidate = "#{base}_#{suffix += 1}" while taken.include?(candidate)
    taken << candidate
    candidate
  end

  # nil for an empty value, so optional keys can be dropped with Hash#compact.
  def self.presence(value)
    value unless value.nil? || value.empty?
  end

  def self.positive(number)
    number if number.to_i.positive?
  end

  # Records anything that could not be converted. Includers provide `context`
  # (where in the release it is) and a shared `@warnings` array.
  module Reporting
    # Returns nil, so a converter can `return todo(...)` to skip something.
    def todo(message)
      @warnings << "#{context}: #{message}"
      nil
    end

    # Non-secret variables as name => value, or nil if there are none. Secrets
    # cannot be exported, so they are reported instead.
    def variables_to_yaml(variables)
      result = (variables || {}).each_with_object({}) do |(name, variable), converted|
        next converted[name] = variable['value'].to_s unless variable['isSecret']

        todo("secret variable '#{name}' was left out; " \
             'add it as a secret pipeline variable or from a variable group or Key Vault')
      end
      Yamlease.presence(result)
    end

    def warn_about_variable_groups(groups)
      return if groups.nil? || groups.empty?

      todo("uses variable group IDs #{groups.join(', ')}; add them as `- group: <name>` under variables")
    end
  end
end
