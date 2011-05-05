#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'
include XYZ
c = 2
model_handle = ModelHandle.new(c,:project)
projects = Project.get_all(model_handle)
pp [:projects,projects]
projects.each do |p|
  tree = p.get_tree()
  #        pp tree
  sample_cmp = tree.values.first[:nodes].values.first[:components].values.first
  file_paths = sample_cmp.get_implementation_file_paths()
  pp file_paths
=begin
TODO
rewite test code to reflect hierch dir structure
        sample_file_asset = file_paths.first[:file_assets].first
        sample_content = sample_file_asset.get_implementation_file_content()
        pp sample_content
=end
end
