#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'yaml'
require 'pp'
require File.expand_path('../../utils/internal/auxiliary', File.dirname(__FILE__))
require File.expand_path('../../utils/internal/log', File.dirname(__FILE__))

input_file = ARGV[0]
output_file = ARGV[1]
component_name = ARGV[2]
key_form = ARGV[3] == "key_form"
raise NameError.new("wrong format for input file") unless input_file =~ /[.]json$/
raise NameError.new("input file does not exist") unless File.exists?(input_file)
output_form =
  if output_file =~ /[.]rb$/ then :hash
  elsif output_file =~ /[.]json$/ then :json
  elsif output_file =~ /[.]yml$/ then :yaml
  else raise NameError.new("wrong format for output file") 
  end
raise NameError.new("no component given") unless component_name

def remove_default_attrs!(component)
  (component["attribute"]||{}).each do |ref,attr_params|
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

def order(component)
  ret = ActiveSupport::OrderedHash.new()
  missing_cmps = component.keys - COMPONENT_KEY_ORDER
  XYZ::Log.error("missing component keys in (#{missing_cmps.join(", ")})") unless missing_cmps.empty?
  COMPONENT_KEY_ORDER.each do |cmp_key|
    if component.has_key?(cmp_key)
      if cmp_key == "attribute"
        attrs = component["attribute"]
        cmp_val = attrs.keys.sort.inject(ActiveSupport::OrderedHash.new()) do |h,attr|
          attr_info = attrs[attr]
          missing_attrs = attr_info.keys - ATTR_KEY_ORDER
          XYZ::Log.error("missing component keys in (#{missing_attrs.join(", ")})") unless missing_attrs.empty?
          ordered_attr_info = ATTR_KEY_ORDER.inject(ActiveSupport::OrderedHash.new()) do |h2,attr_key|
            attr_info.include?(attr_key) ? h2.merge(attr_key =>  attr_info[attr_key]) : h2
          end
          h.merge(attr => ordered_attr_info)
        end
      else 
        cmp_val = component[cmp_key] 
      end
      ret[cmp_key] = cmp_val
    end
  end
  ret
end
COMPONENT_KEY_ORDER = 
  [
   "display_name",
   "description",
   "ui",
   "type",
   "basic_type",
   "specific_type",
   "component_type",
   "only_one_per_node",
   "attribute",
   "monitoring_item",
   "external_ref",
   "ds_key",
   "ds_attributes"
]

ATTR_KEY_ORDER = 
  [
   "display_name",
   "description",
   "data_type",
   "value_asserted",
   "is_port",
   "semantic_type_summary",
   "semantic_type",
   "required",
   "external_ref",
   "read_only",
   "dynamic",
   "cannot_change",
   "hidden",
]
        
def key_form(obj)
  if obj.kind_of?(Hash)
    obj.inject({}){|h,kv|h.merge(kv[0].to_sym => key_form(kv[1]))}
  elsif obj.kind_of?(Array)
    obj.map{|el|key_form(el)}
  else
    obj
  end
end

hash_content = XYZ::Aux.hash_from_file_with_json(input_file)
component = hash_content["library"]["test"]["component"][component_name]
raise NameError.new("cannot find component") unless component
remove_default_attrs!(component)
ordered_component = order(component) 
hash_output = {component_name => ordered_component}
File.open(output_file, "w") do |f|
  case output_form
    when :hash
      f.write(XYZ::Aux.pp_form(key_form ? key_form(hash_output) : hash_output))
    when :yaml
      YAML.dump(hash_output,f)
    when :json
      f.puts(JSON.pretty_generate(hash_output))
  end
end

