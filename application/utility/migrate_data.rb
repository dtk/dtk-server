#!/usr/bin/env ruby

unless ARGV[0]
  puts "You need to pass tenant name! (e.g. dtk16)"
  exit
end

root = File.expand_path('../', File.dirname(__FILE__))

require root + '/app'
XYZ::Model.migrate_data_new({ :db => DBinstance }, ARGV[0])
