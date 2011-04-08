#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'pp'
require File.expand_path('../../utils/internal/auxiliary', File.dirname(__FILE__))

def remove_default_attrs!(component)
  (component["attribute"]||{}).each do |ref,attr|
    attr_params = attr.keys.first
    attr_params.each do |k,v|
      if ATTR_DEFAULTS.has_key?(k) and ATTR_DEFAULTS[k] == v
        attr_params.delete(k)
      end
    end
  end
end
#TODO: if make this into real fn; make it datadriven from schema info 
ATTR_DEFAULTS = {
  "read_only" => false, 
  "dynamic" => false, 
  "cannot_change" => false,
  "required" => false, 
  "hidden" => false,
  "is_port" => false
}

input_file = ARGV[0]
output_file = ARGV[1]
component_name = ARGV[2]
raise NameError.new("wrong format for input file") unless input_file =~ /[.]json$/
raise NameError.new("input file does not exist") unless File.exists?(input_file)
raise NameError.new("wrong format for output file") unless output_file =~ /[.]rb$/
raise NameError.new("no component given") unless component_name
hash_content = XYZ::Aux.hash_from_file_with_json(input_file)
component = hash_content["library"]["test"]["component"]
raise NameError.new("cannot find component") unless component
remove_default_attrs!(component)
File.open(output_file, "w") do |f|
  f.write(XYZ::Aux.pp_form({component_name => component}))
end

