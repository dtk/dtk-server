#!/usr/bin/env ruby
require 'rubygems'
require 'pp'

Root = File.expand_path('../../', File.dirname(__FILE__))
["auxiliary", "errors", "log","hash_object", "generate_meta", "config_agent/adapters/puppet/parser"].each do |f|
  require "#{Root}/utils/internal/#{f}.rb"
end

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
refinement_hash = meta_generator.generate_refinement_hash(r8_parse,module_name)
#pp refinement_hash

#in between here refinement has would have through user interaction the user set the needed unknowns
#mock_user_updates_hash!(refinement_hash)
render_hash = refinement_hash.render_hash_form()
render_hash.write_yaml(STDOUT)
end
