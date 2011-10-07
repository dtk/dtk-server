#!/usr/bin/env ruby
require 'rubygems'
require 'pp'

Root = File.expand_path('../../', File.dirname(__FILE__))
require "#{Root}/utils/internal/auxiliary.rb"
require "#{Root}/utils/internal/hash_object.rb"
require "#{Root}/utils/internal/generate_meta.rb"
require "#{Root}/utils/internal/config_agent/adapters/puppet/parser.rb"

module_path_or_file = ARGV[0].gsub(/\/$/,"")
file = module_name = nil
if File.file?(module_path_or_file)
  file = module_path_or_file
  module_name = ARGV[1]
else
  file = "#{module_path_or_file}/manifests/init.pp"
  if module_path_or_file =~ /.+\/(.+$)/
    module_name = $1
  end
end
module_name.gsub!(/^puppet-/,"")

Puppet[:manifest] = file
environment = "production"
krt = Puppet::Node::Environment.new(environment).known_resource_types
krt_code = krt.hostclass("").code
r8_parse = XYZ::Puppet::ModulePS.new(krt_code)
#pp r8_parse
begin
meta_generator = XYZ::GenerateMeta.create("1.0")
#TODO: should be able to figure this out "puppet" from r8_parse
meta_hash = meta_generator.generate_hash(r8_parse,module_name,"puppet")
pp meta_hash
end
