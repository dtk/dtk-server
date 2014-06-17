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
   opts.on( '-p', '--push', 'Push changes' ) do 
     options[:push] = true
   end
end.parse!
test_type = ARGV[0]

require root + '/app'
include XYZ

def get_file_asset(path)
  c = 2
  repo,af_path = (path =~ Regexp.new("(^[^/]+)/(.+$)"); [$1,$2])
  sp_hash = {
    :filter => [:eq, :path, af_path],
    :cols => [:id,:path,:implementation_info]
  }
  file_asset_mh = ModelHandle.new(c,:file_asset)
  ret = Model.get_objects_from_sp_hash(file_asset_mh,sp_hash).find{|x|x[:implementation][:repo] == repo}
  raise "file asset #{path} not found" unless ret
  ret
end
  
def get_file(options)
  file_asset = get_file_asset(options[:file_path])
  file_asset.get_content()
end

def edit_file(options)
  file_asset = get_file_asset(options[:file_path])
  content = file_asset.get_content()
  filename = "tmp-"
  0.upto(20) { filename += rand(9).to_s }
  filename << ".txt"
  filename = File.join(Dir.tmpdir, filename)
  new_content = nil
  begin
    File.open(filename, "w") do |f|
      f.sync = true
      f.puts content
    end
    system("#{ENV["EDITOR"] || "emacs"} #{filename}")
     
    new_content = File.open(filename){|f|f.read}
   ensure
    File.unlink(filename)
   end
   file_asset.update_content(new_content)
  if options[:push]
    # TODO: project stubbed
    context = {:implementation => file_asset[:implementation], :project => {:ref => "project1"}}
    RepoManager.push_implementation(context)
  end

end

case test_type
  when "get_file" 
    contents = get_file(options)
    contents.each_line{|l|STDOUT << l}
    STDOUT << "\n"
  when "edit_file"
    edit_file(options)
  else
    raise "Illegal test type: #{test_type}"
end
