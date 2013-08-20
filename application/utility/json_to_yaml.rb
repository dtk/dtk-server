#!/usr/bin/env ruby
unless json_source_path = ARGV[0]
  puts 'usage: json_to_yaml.rb PATH-TO-JSON-FILE [PATH-To-YAML] [--overwrite]'
  exit 1
end
unless File.exists?(json_source_path)
  puts "File (#{json_source_path}) does not exist"
  exit 1
end
yaml_file_path = ARGV[1]||json_source_path.gsub(/\.[^\.]+$/,'') + '.yaml'
if File.exists?(yaml_file_path)
  unless  ARGV[2] == '--overwrite'
    puts "File (#{yaml_file_path} exists; this fn overwrites it; either remove or use option flag --overwrite"
    exit 1
  end
end

root = File.expand_path('../../', File.dirname(__FILE__))
require root + '/application/require_first'
require root + '/utils/internal/auxiliary'
require root + '/utils/internal/error'
require 'json'
require 'yaml'
include XYZ
json_content = File.open(json_source_path){|f|f.read}
hash_content = Aux.json_parse(json_content,json_source_path)
yaml_content = Aux.serialize(hash_content,:yaml)
File.open(yaml_file_path,'w'){|f|f << yaml_content}
puts "YAML file located at: #{yaml_file_path}\n"

