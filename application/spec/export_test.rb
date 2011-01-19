#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'
export_file = ARGV[0]
container_uri_list = ARGV[1]
prefix_is_top = ARGV[2] =~ /^top/
opts = prefix_is_top ? {:prefix_is_top => true} : {}
target_id_handles = container_uri_list.split(",").map{|uri|XYZ::IDHandle[:c => 2, :uri => uri]}
XYZ::Object.export_objects_to_file(target_id_handles,export_file,opts)
