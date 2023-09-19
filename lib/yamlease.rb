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
    self.yaml["workflowTasks"]
  end
end

class Task
  attr_reader :name, :url

  def initialize(name, url)
    @name = name
    @url = url
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

  def get_task_by_id(id)
    matches = File.read("task_map.txt").split("\n").select do |line|
      task_id, _task_name = line.split(" ")
      task_id.downcase == id.downcase
    end

    matches.length > 0 ? matches[0].split(" ")[1] : "Unknown"

  end

end

