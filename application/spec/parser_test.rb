#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
Root = File.expand_path('../../', File.dirname(__FILE__))
require "#{Root}/utils/internal/auxiliary.rb"
require "#{Root}/utils/internal/hash_object.rb"
require "#{Root}/utils/internal/generate_meta.rb"
require "#{Root}/utils/internal/config_agent/adapters/puppet/parser.rb"

file = ARGV[0]
file ||= "/root/r8server-repo/puppet-mysql/manifests/classes/master.pp"
Puppet[:manifest] = file
environment = "production"
krt = Puppet::Node::Environment.new(environment).known_resource_types
krt_code = krt.hostclass("").code
krt_code.children.each do |ast_item|
  r8_parse = XYZ::Puppet::ComponentPS.create(ast_item,{:foo => true})
  pp r8_parse
end
#pp krt_code
