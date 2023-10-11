Gem::Specification.new do |s|
  s.name = "yamlease"
  s.version = "0.0.2"
  s.summary = "Convert Azure DevOps Release Pipelines to YAML"
  s.description = "If you have a release pipeline in Azure DevOps, this gem will convert it to YAML.  Export the release
definition to yaml and pipe it to this tool."
  s.authors = ["Julian Simpson"]
  s.email = "simpsonjulian@gmail.com"
  s.files = ["bin/ye", "lib/yamlease.rb", "lib/pipeline.erb", "lib/task_map.txt"]
  s.executables = "ye"
  s.homepage =
    "https://rubygems.org/gems/yamlease"
  s.license = "AGPL-3.0"
end