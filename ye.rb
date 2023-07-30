#!/usr/bin/env ruby
#
require_relative 'lib/yamlease'

rp = ReleasePipeline.new(ARGV.first)
rp.stages.each do |stage|
  puts stage[:name]

  stage[:tasks].each do |task|
    puts "  #{task["name"]} (#{task["taskId"]})"
  end
end