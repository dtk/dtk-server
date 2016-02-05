#!/usr/bin/env ruby
#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
unless json_source_path = ARGV[0]
  puts 'usage: json_to_yaml.rb PATH-TO-JSON-FILE [PATH-To-YAML] [--overwrite]'
  exit 1
end
unless File.exist?(json_source_path)
  puts "File (#{json_source_path}) does not exist"
  exit 1
end
yaml_file_path = ARGV[1] || json_source_path.gsub(/\.[^\.]+$/, '') + '.yaml'
if File.exist?(yaml_file_path)
  unless  ARGV[2] == '--overwrite'
    puts "File (#{yaml_file_path} exists; this fn overwrites it; either remove or use option flag --overwrite"
    exit 1
  end
end

module XYZ; end
DTK = XYZ

root = File.expand_path('../../', File.dirname(__FILE__))
require root + '/application/require_first'

require root + '/utils/internal/auxiliary'
require root + '/utils/internal/yaml_helper'
require root + '/utils/internal/error'
require 'json'
require 'yaml'
include XYZ
json_content = File.open(json_source_path) { |f| f.read }
hash_content = Aux.json_parse(json_content, json_source_path)
yaml_content = Aux.serialize(hash_content, :yaml)
File.open(yaml_file_path, 'w') { |f| f << yaml_content }
puts "YAML file located at: #{yaml_file_path}\n"