#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'
require 'json'
# required since overloads what is returned by YAML::load_file
require 'active_support/ordered_hash'
recipes = ARGV[0].split(",")
node_json_file = ARGV[1]
type = :yaml

root = File.expand_path('../../', File.dirname(__FILE__))
require "#{root}/utils/internal/errors"
require "#{root}/utils/internal/log"
require "#{root}/application/config/environment_config"

def get_hash_output(recipes,type)
  # TODO: assuming all from same cookbook
  cookbook = recipes.first.gsub(/::.+$/,"")
  meta_file = "#{R8::EnvironmentConfig::CoreCookbooksRoot}/#{cookbook}/r8meta.#{TypeMapping[type]}"
  raise XYZ::Error.new("file #{meta_file} does not exist") unless File.exists? meta_file
  meta_content = YAML.load_file(meta_file)
  # prune out all recipes that are not in meta data
  meta_recipes = meta_content.keys.map{|r|r.gsub(/__/,"::")}
  pruned_recipes = recipes & meta_recipes
  raise XYZ::Error.new("None of the specified recipes appear in the meta data") if pruned_recipes.empty?

  # set run list
  hash_output =  ActiveSupport::OrderedHash.new()
  hash_output.merge!("run_list" => pruned_recipes.map{|r|"recipe[#{r}]"})
    # set default values and stubs
    pruned_recipes.each do |r|
      (meta_content[r.gsub(/::/,"__")]["attribute"]||{}).each do |attr_ref,attr_info|
        required = attr_info["required"]
        default = attr_info["value_asserted"]
        next unless required or default
        add_attribute!(hash_output,attr_ref,attr_info,default || "**STUBVALUE")
    end
  end
  hash_output
end

TypeMapping = {
  :yaml => "yml"
}

def add_attribute!(hash_output,attr_ref,attr_info,value)
  unless external_ref_path = (attr_info["external_ref"]||{})["path"]
    XYZ::Log.error("Missing external ref path for attribute #{attr_ref}")
    return
  end
  path = external_ref_path.gsub(/((node)|(service))\[/,"").gsub(/\]$/,"").split("][")
  deep_merge!(hash_output,path,value)
end

def deep_merge!(target,path,value)
  if path.size == 1
    target[path.first] = value
  else
    target[path.first] ||= Hash.new
    deep_merge!(target[path.first],path[1..path.size-1],value)
  end
end

    
=begin
{
  "resolver": {
    "nameservers": [ "10.0.0.1" ],
    "search":"int.example.com"
  },
  "run_list": [ "recipe[resolver]" ]
}
=end
hash_output = get_hash_output(recipes,type)
File.open(node_json_file,"w"){|f|f.puts(JSON.pretty_generate(hash_output))}

