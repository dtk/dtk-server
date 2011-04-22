#!/usr/bin/env ruby
import_file = ARGV[0]
container_uri = ARGV[1] || "/"
flag = ARGV[2]
Library = "test" #TODO: stub 

Root = File.expand_path('../', File.dirname(__FILE__))
require "#{Root}/config/environment_config.rb"

BaseDir = R8::EnvironmentConfig::CoreCookbooksRoot

def load_component_opts(type)
  files = Dir.glob("#{BaseDir}/*/r8meta.#{TypeMapping[type]}")
  if files.empty? 
    {} 
  else
    {:r8meta => {:type => type, :library => Library, :files => files}}
  end
end
TypeMapping = {
  :yaml => "yml"
}

opts = 
  case flag 
    when "delete" then {:delete => true} 
    when "r8meta_yaml" then load_component_opts(:yaml)
    else {}
  end

require Root + '/app'
opts.merge!(:add_implementation_file_refs => {:library => Library, :base_directory => BaseDir})
XYZ::Object.import_objects_from_file(XYZ::IDHandle[:c => 2, :uri => container_uri],import_file,opts)


