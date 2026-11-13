# frozen_string_literal: true

require_relative 'lib/yamlease/version'

Gem::Specification.new do |s|
  s.name = 'yamlease'
  s.version = Yamlease::VERSION
  s.summary = 'Convert Azure DevOps classic release pipelines to YAML'
  s.description = 'Converts an Azure DevOps classic release definition, exported with ' \
                  '`az pipelines release definition show`, into a multi-stage YAML pipeline. ' \
                  'Anything it cannot convert is listed as a TODO at the top of the output.'
  s.authors = ['Julian Simpson']
  s.email = 'simpsonjulian@gmail.com'
  s.files = Dir['lib/**/*.rb'] + %w[bin/ye lib/task_map.txt README.md LICENSE CHANGELOG.md]
  s.bindir = 'bin'
  s.executables = ['ye']
  s.homepage = 'https://github.com/builddoctor/yamlease'
  s.license = 'AGPL-3.0-only'
  s.required_ruby_version = '>= 3.1'
  s.metadata = {
    'source_code_uri' => 'https://github.com/builddoctor/yamlease',
    'changelog_uri' => 'https://github.com/builddoctor/yamlease/blob/main/CHANGELOG.md',
    'rubygems_mfa_required' => 'true'
  }
end
