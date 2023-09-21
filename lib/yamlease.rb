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
  attr_reader :name, :url, :yaml
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

  def inputs
    @yaml.inputs.delete_if do |key, value|
      value == ""
    end
  end

end

class TaskDefinition
  def initialize
    @file_read = File.read("task_map.txt")
  end

  def yaml_name(id)
    matches = @file_read.split("\n").select do |line|
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
  attr_reader :url

  def initialize(filename = nil)
    self.parse(filename)
  end

  def parse(filename = "show.yml")
    @pipeline = YAML.load(File.read(filename)).with_dot_access
    @url = @pipeline["url"]
  end

  def transform

  end

  def jobs
    0
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

