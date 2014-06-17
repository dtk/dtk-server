#!/usr/bin/env ruby
require 'rubygems'
require 'fileutils'
Root = File.expand_path('../', File.dirname(__FILE__))
require "#{Root}/config/environment_config.rb"

source_dir = ARGV[0]
target_dir = ARGV[1]
Dir.foreach(target_dir){|f|raise "#{target_dir} is not an empty directory" unless f =~ /^\./}

Git = R8::EnvironmentConfig::GitExecutable
# modified from http://iamneato.com/2009/07/28/copy-folders-recursively
def recursive_copy_and_git_init_clone(src_dir,dest_dir,level=0)
  Dir.foreach(src_dir) do |file|
    next if file =~ /^\./
    s = File.join(src_dir, file)
    d = File.join(dest_dir, file)
    if File.directory?(s)
      if level == 0
        begin
          `#{Git} clone gitolite@localhost:#{file} #{d}`
        rescue Exception
        end
      else
        FileUtils.mkdir(d)
      end
      recursive_copy_and_git_init_clone(s,d,level+1)
    elsif level > 0
      FileUtils.cp(s, d)
    end
  end
end


recursive_copy_and_git_init_clone(source_dir,target_dir)


Dir.foreach(target_dir) do |dir|
  Dir.chdir(File.join(target_dir,dir)) do 
    `#{Git} add .`
    `#{Git} commit -m 'initializing-#{dir}'`
    `#{Git} push origin master`
  end
end


