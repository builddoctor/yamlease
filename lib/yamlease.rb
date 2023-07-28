require 'rspec'
require 'yaml'

class ReleasePipeline
  attr_reader :url

  def initialize
    self.parse
  end

  def parse(filename = "show.yml")
    pipeline = YAML.load(File.read(filename))
    @url = pipeline["url"]
  end


end

