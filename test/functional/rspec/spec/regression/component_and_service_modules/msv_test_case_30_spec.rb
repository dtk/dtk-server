#!/usr/bin/env ruby
# Test Case 30: NEG - Import component module A from git which has dependency on component module B that does not exist on server yet

require 'rubygems'
require 'active_record'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'
require './lib/component_modules_spec'

dependency_module = "maestrodev/rvm"
component_module_name = "geminabox"
local_component_module_name = "local:geminabox"
git_ssh_repo_url = "git@github.com:maestrodev/puppet-geminabox.git"
component_module_filesystem_location = "~/dtk/component_modules/local"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 30: NEG - Import component module A from git which has dependency on component module B that does not exist on server yet" do
  before(:all) do
    puts "**********************************************************************************************************************************************************************",""
  end

  context "NEG - Import component module with dependency from provided git repo" do
    include_context "NEG - Import component module with dependency from provided git repo", component_module_name, git_ssh_repo_url, dependency_module
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, component_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, local_component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end
