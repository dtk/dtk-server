#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'
export_file = ARGV[0]
container_uri = ARGV[1]
XYZ::Object.export_objects_to_file(XYZ::IDHandle[:c => 2, :uri => container_uri],export_file)
