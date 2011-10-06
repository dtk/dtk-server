#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
Root = File.expand_path('../../', File.dirname(__FILE__))
require "#{Root}/utils/internal/auxiliary.rb"
require "#{Root}/utils/internal/hash_object.rb"
require "#{Root}/utils/internal/generate_meta.rb"
require "#{Root}/utils/internal/config_agent/adapters/puppet/parser.rb"

module_path = ARGV[0].gsub(/\/$/,"")
file = "#{module_path}/manifests/init.pp"
if module_path =~ /.+\/(.+$)/
  module_name = $1
  module_name.gsub!(/^puppet-/,"")
end
Puppet[:manifest] = file
environment = "production"
krt = Puppet::Node::Environment.new(environment).known_resource_types
krt_code = krt.hostclass("").code
r8_parse = XYZ::Puppet::ModulePS.new(krt_code)
#pp r8_parse
meta_generator = XYZ::GenerateMeta.create("1.0")
meta_hash = meta_generator.generate_hash(r8_parse,module_name)
pp meta_hash
