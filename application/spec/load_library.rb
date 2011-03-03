#!/usr/bin/env ruby
require 'rubygems'
require 'restclient'
require 'pp'
host_addr = "ec2-184-73-175-145.compute-1.amazonaws.com"
%w{chef ec2 user_data}.each do |source|
  puts "loading from source #{source}"
  RestClient.get "http://#{host_addr}:7000/xyz/devtest/discover_and_update/#{source}/library/test"
  puts "complete"
  puts "============================================="
end
