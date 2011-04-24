#!/usr/bin/env ruby
require 'yaml'
cookbook = ARGV[0]
type = :yaml

TypeMapping = {
  :yaml => "yml"
}

root = File.expand_path('../', File.dirname(__FILE__))
require "#{root}/config/environment_config.rb"
meta_file = "#{R8::EnvironmentConfig::CoreCookbooksRoot}/#{cookbook}/r8meta.#{TypeMapping[type]}"
raise NameError.new("file #{meta_file} does not exist") unless File.exists? meta_file
meta_content = YAML.load_file(meta_file)
meta_content


