# frozen_string_literal: true

require 'open3'
require 'rbconfig'
require 'yaml'

module FixtureHelpers
  FIXTURES = File.expand_path('fixtures', __dir__)
  YE = File.expand_path('../bin/ye', __dir__)

  def fixture_path(name)
    File.join(FIXTURES, name)
  end

  # Runs the CLI against a fixture; returns [stdout, stderr, Process::Status].
  # Results are cached per fixture because each run starts a Ruby process.
  def run_ye(fixture)
    FixtureHelpers.ye_results[fixture] ||= Open3.capture3(RbConfig.ruby, YE, fixture_path(fixture)).freeze
  end

  def self.ye_results
    @ye_results ||= {}
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers
  config.extend FixtureHelpers
end
