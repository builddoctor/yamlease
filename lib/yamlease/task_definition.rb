# frozen_string_literal: true

module Yamlease
  # Looks up the YAML name of a built-in task from lib/task_map.txt.
  class TaskDefinition
    TASK_MAP = File.expand_path('../task_map.txt', __dir__)

    # [id, name, major version or nil] for every task directory in
    # microsoft/azure-pipelines-tasks, e.g. "AzureCLIV2" => ["...", "AzureCLI", 2].
    def self.task_map
      @task_map ||= File.readlines(TASK_MAP, chomp: true).filter_map do |line|
        task_id, directory = line.split(' ', 2)
        next unless directory

        name, version = directory.match(/\A(.*?)(?:V(\d+))?\z/).captures
        [task_id.downcase, name, version&.to_i]
      end
    end

    # Returns [yaml_name, exact] or [nil, false] when the task is not known.
    # Without a version, the highest known version is used.
    def self.lookup(id, major = nil)
      candidates = task_map.select { |task_id, _, _| task_id == id.to_s.downcase }
      return [nil, false] if candidates.empty?
      return [latest(candidates), true] if major.nil?

      major = major.to_i
      match = for_version(candidates, major)
      match ? ["#{match[1]}@#{major}", true] : [latest(candidates), false]
    end

    def self.yaml_name(id, major = nil)
      lookup(id, major).first || 'Unknown'
    end

    # Tasks from before versioned directories have no version in the map.
    def self.for_version(candidates, major)
      candidates.find { |_, _, version| version == major } ||
        candidates.find { |_, _, version| version.nil? }
    end

    def self.latest(candidates)
      _, name, version = candidates.max_by { |_, _, v| v.to_i }
      version ? "#{name}@#{version}" : name
    end
    private_class_method :for_version, :latest
  end
end
