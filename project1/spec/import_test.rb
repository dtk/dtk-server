#!/usr/bin/env ruby
import_file = ARGV[0]
library_uri = ARGV[1]
root = File.expand_path('../', File.dirname(__FILE__))

require root + '/app'


XYZ::Object.import_objects_from_file(XYZ::IDHandle[:c => 2, :uri => library_uri],import_file)
