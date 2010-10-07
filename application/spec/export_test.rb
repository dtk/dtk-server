#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'
export_file = ARGV[0]
container_uri_list = ARGV[1]

target_id_handles = container_uri_list.split(",").map{|uri|XYZ::IDHandle[:c => 2, :uri => uri]}
opts={}
XYZ::Object.export_objects_to_file(target_id_handles,export_file,opts)
