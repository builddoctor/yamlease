#!/usr/bin/env ruby
#
require_relative 'lib/yamlease'
require 'erb'

rp = ReleasePipeline.new(ARGV.first)

stages = rp.stages


template = ERB.new(File.read("lib/pipeline.erb"), trim_mode: "-")
puts template.result(binding)

