#!/usr/bin/env ruby
require 'rubygems'
require 'optparse'
require 'pp'
root = File.expand_path('../', File.dirname(__FILE__))
options = Hash.new
OptionParser.new do|opts|
   opts.banner = "Usage: file_test.rb TEST-TYPE"
 
   # Define the options, and what they do
   opts.on( '-f', '--filename FILENAME', 'File name' ) do |f|
     options[:filename] = f
   end
end.parse!
test_type = ARGV[0]

require root + '/app'
include XYZ
c = 2
if test_type == "get_file"
  sp_hash = {
    :filter => [:eq, :path, options[:filename]],
    :cols => [:id,:path]
  }
  file_asset_mh = ModelHandle.new(c,:file_asset)
  file_asset = Model.get_objects_from_sp_hash(file_asset_mh,sp_hash).first
  raise Error.new("file asset #{options[:filename]} not found") unless file_asset
  pp file_asset.get_content()
end

=begin
model_handle = ModelHandle.new(c,:project)
projects = Project.get_all(model_handle)
pp [:projects,projects]
projects.each do |p|
  tree = p.get_tree()
  #        pp tree
  sample_cmp = tree.values.first[:nodes].values.first[:components].values.first
  file_paths = sample_cmp.get_implementation_file_paths()
  pp file_paths
        sample_file_asset = file_paths.first[:file_assets].first
        sample_content = sample_file_asset.get_implementation_file_content()
        pp sample_content
=end

