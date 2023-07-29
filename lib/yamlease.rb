require 'rspec'
require 'yaml'

class ReleasePipeline
  attr_reader :url

  def initialize(filename = nil)
    self.parse(filename)
  end

  def parse(filename = "show.yml")
    @pipeline = YAML.load(File.read(filename))
    @url = @pipeline["url"]
  end

  def stages
    @pipeline["environments"].collect do |stage|
      # puts stage.inspect
      { name: stage["name"], url: stage["badgeUrl"], tasks: stage["deployPhases"][0]["workflowTasks"]}
    end
  end




end

