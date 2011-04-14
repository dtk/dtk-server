#!/usr/bin/env ruby
import_file = ARGV[0]
container_uri = ARGV[1] || "/"
flag = ARGV[2]
Root = File.expand_path('../', File.dirname(__FILE__))

def load_component_opts(type)
  files = Dir.glob("#{Root}/spec/chef/site-cookbooks/*/r8meta.#{TypeMapping[type]}")
  if files.empty? 
    {} 
  else
    library = "test" #TODO: stub 
    {:r8meta => {:type => type, :library => library, :files => files}}
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
XYZ::Object.import_objects_from_file(XYZ::IDHandle[:c => 2, :uri => container_uri],import_file,opts)


