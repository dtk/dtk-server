#!/usr/bin/env ruby
require 'rubygems'
Root = File.expand_path('../', File.dirname(__FILE__))
require 'pp'
require Root + '/app'
include XYZ

def model_handle(model_name)
  c = 2
  ModelHandle.new(c,model_name)
end

RepoManager.delete_all_branches(model_handle(:repo))

