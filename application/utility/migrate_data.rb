#!/usr/bin/env ruby

unless ARGV[0]
  puts "You need to pass Tenant Name! (e.g. ruby utility/migrate_data.rb dtk16)"
  exit
end

puts "WARNING!"
puts
puts "************* PROVIDED DATA *************"
puts " TENANT-ID:    #{ARGV[0]}"
puts "*****************************************"
puts "Make sure that provided data is correct, and press ENTER to continue OR CTRL^C to stop"
a = $stdin.gets


root = File.expand_path('../', File.dirname(__FILE__))

require root + '/app'
XYZ::Model.migrate_data_new({ :db => DBinstance }, ARGV[0])
