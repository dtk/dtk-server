#!/usr/bin/env ruby
#Test Case 30: NEG - Import Module A from git which has dependency on Module B that does not exist on server yet

require 'rubygems'
require 'active_record'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/services_spec'
require './lib/modules_spec'

dependency_module = "maestrodev/wget"
module_name = "maven"
git_ssh_repo_url = "git@github.com:maestrodev/puppet-maven.git"
module_filesystem_location = "~/dtk/component_modules"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 30: NEG - Import Module A from git which has dependency on Module B that does not exist on server yet" do

  before(:all) do
    puts "**************************************************************************************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 30: NEG - Import Module A from git which has dependency on Module B that does not exist on server yet"
    puts "**************************************************************************************************************************************************"
    puts ""
  end

  context "NEG - Import module with dependency from provided git repo" do
    include_context "NEG - Import module with dependency from provided git repo", module_name, git_ssh_repo_url, dependency_module
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end

  after(:all) do
    puts "", ""
  end
end