require 'rspec'
require 'yaml'
require "hash_with_dot_access"



class Stage
  attr_reader :name, :url, :yaml
  attr_writer :yaml

  def initialize(name, url)
    @name = name
    @url = url
    @tasks = []
  end

  def jobs
    self.yaml["deployPhases"].collect do |job|
      _job = Job.new(job.name, job.badgeUrl)
      _job.yaml = job
      _job
    end
  end

end

class Job
  attr_reader :url, :yaml
  attr_writer :yaml

  def initialize(name, url)
    @name = name
    @url = url
  end

  def tasks
    self.yaml["workflowTasks"].collect do |task|
      Task.new(yaml = task)
    end
  end

  def name
    parts = @name.split(" ")
    parts.map do |part|
      first_character = part[0]
      part[0] = first_character.upcase
      part
    end.join("")
  end

end

class Task
  attr_writer :yaml
  attr_reader :display_name, :task_id

  def initialize(yaml)
    @yaml = yaml
    @display_name = yaml.name
    @task_id = yaml.taskId
  end

  def yaml_name
    TaskDefinition.yaml_name(task_id)
  end

  def convert_vars_to_yaml(text)
    text.gsub(/\$\((.+)\)/, '${{\1}}')
  end

  def inputs
    _inputs = @yaml.inputs
    _inputs.delete_if { |_, value| value == "" }
    _inputs.each do |key, value|
      if value.include?('*')
        _inputs[key] = "'#{value}'"
      end
      value = _inputs[key]
      _inputs[key] = convert_vars_to_yaml(value)
    end
    _inputs

  end
end

class TaskDefinition
  def initialize
    task_map = File.dirname(File.absolute_path(__FILE__)) + "/task_map.txt"
    @tasks = File.read(task_map)
  end

  def yaml_name(id)
    matches = @tasks.split("\n").select do |line|
      task_id, _task_name = line.split(" ")
      task_id.downcase == id.downcase
    end

    task_name = matches.length > 0 ? matches[0].split(" ")[1] : "Unknown"
    task_name.sub(/V(\d+)$/, '@\1')
  end

  def self.yaml_name(id)
    self.new.yaml_name(id)
  end

end

class ReleasePipeline
  attr_reader :url, :variables

  def initialize(filename = nil)
    raise ArgumentError.new("I need a YAML file to parse") if filename.nil?
    self.parse(filename)
  end

  def parse(filename = "show.yml")
    @pipeline = YAML.load(File.read(filename)).with_dot_access
    @url = @pipeline["url"]
    @variables = @pipeline["variables"]
  end

  def variables_to_yaml
    response = {}
    @variables.each do |key, value|
      response[key] = value.value
    end
    response
  end

  # stages are environments
  def stages
    @pipeline["environments"].collect do |stage|
      _stage = Stage.new(stage.name, stage.badgeUrl)
      _stage.yaml = stage
      _stage
    end

  end

end

