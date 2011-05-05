#!/usr/bin/env ruby
require 'rubygems'
require 'optparse'
require 'pp'
require 'tmpdir'
root = File.expand_path('../', File.dirname(__FILE__))
options = Hash.new
OptionParser.new do|opts|
   opts.banner = "Usage: file_test.rb TEST-TYPE"
 
   # Define the options, and what they do
   opts.on( '-f', '--filename FILENAME', 'File name' ) do |f|
     options[:file_path] = f
   end
end.parse!
test_type = ARGV[0]

require root + '/app'
include XYZ

def get_file_asset(path)
  c = 2
  sp_hash = {
    :filter => [:eq, :path, path],
    :cols => [:id,:path]
  }
  file_asset_mh = ModelHandle.new(c,:file_asset)
  ret = Model.get_objects_from_sp_hash(file_asset_mh,sp_hash).first
  raise "file asset #{path} not found" unless ret
  ret
end
  
def get_file(options)
  file_asset = get_file_asset(options[:file_path])
  file_asset.get_content()
end

def edit_file(options)
  file_asset = get_file_asset(options[:file_path])
  contents = file_asset.get_content()
  filename = "tmp-"
  0.upto(20) { filename += rand(9).to_s }
  filename << ".txt"
  filename = File.join(Dir.tmpdir, filename)
  File.open(filename, "w") do |f|
    f.sync = true
    f.puts contents
  end
  system("#{ENV["EDITOR"] || "emacs"} #{filename}")

  ret = File.open(filename){|f|f.read}
  File.unlink(filename)
  ret
end

case test_type
  when "get_file" then pp get_file(options)
  when "edit_file" then edit_file(options)
end
