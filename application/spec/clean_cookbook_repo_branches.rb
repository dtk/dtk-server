#!/usr/bin/env ruby
require 'rubygems'
root = File.expand_path('../', File.dirname(__FILE__))
require 'pp'
#require root + '/app'
Root = File.expand_path('../', File.dirname(__FILE__))
require "#{Root}/config/environment_config.rb"
require "#{Root}/../utils/internal/auxiliary.rb"
require "#{Root}/../utils/internal/repo.rb"

XYZ::RepoManager.delete_all_branches()
