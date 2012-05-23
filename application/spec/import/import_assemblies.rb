#!/usr/bin/env ruby
#TODO: for test
require File.expand_path('common', File.dirname(__FILE__))
require 'json'
json = File.open("/root/test_client/assemblies.json"){|f|f.read}
hash = JSON.parse(json) 
server = R8Server.new("superuser","all")
server.create_private_library_assemblies(hash["assemblies"],hash["node_bindings"])


