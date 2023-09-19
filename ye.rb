#!/usr/bin/env ruby
#
require_relative 'lib/yamlease'
require 'erb'

rp = ReleasePipeline.new(ARGV.first)

stages = rp.stages
# stages.each do |stage|
#   puts stage.name
#   stage.jobs.each do |job|
#     puts " * #{job.name}"
#     job.tasks.each do |task|
#       puts task.name
#     end
#   end
# end

template = ERB.new(File.read("lib/pipeline.erb"))
puts template.result(binding)

