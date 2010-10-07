#!/usr/bin/env ruby
import_file = ARGV[0]
container_uri = ARGV[1] || "/"
delete_flag = ARGV[2]
root = File.expand_path('../', File.dirname(__FILE__))
opts = delete_flag == "delete" ? {:delete => true} : {}
require root + '/app'
XYZ::Object.import_objects_from_file(XYZ::IDHandle[:c => 2, :uri => container_uri],import_file,opts)


