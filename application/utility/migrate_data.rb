#!/usr/bin/env ruby

unless ARGV[0] && ARGV[1]
  puts "You need to pass tenant name and tenant DB ID! (e.g. ruby utility/migrate_data.rb dtk16 2)"
  exit
end

puts "WARNING!"
puts
puts "************* PROVIDED DATA *************"
puts " TENANT-ID:    #{ARGV[0]}"
puts " TENANT-DB-ID: #{ARGV[1]}"
puts "*****************************************"
puts "Make sure that provided data is correct, and press any key to continue OR CTRL^C to stop"
system('read')


root = File.expand_path('../', File.dirname(__FILE__))

require root + '/app'
XYZ::Model.migrate_data_new({ :db => DBinstance }, ARGV[0])
