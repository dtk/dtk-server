#!/usr/bin/env ruby
#Test Case 29: Import module A and then module B when module B has dependency on module A

require 'rubygems'
require 'active_record'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/services_spec'
require './lib/modules_spec'

module_name_1 = "wget"
git_ssh_repo_url_1 = "git@github.com:maestrodev/puppet-wget.git"
module_name_2 = "maven"
git_ssh_repo_url_2 = "git@github.com:maestrodev/puppet-maven.git"
module_filesystem_location = "~/dtk/component_modules"
$assembly_id = 0
dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 29: Import module A and then module B when module B has dependency on module A" do

  before(:all) do
    puts "***************************************************************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 29: Import module A and then module B when module B has dependency on module A"
    puts "***************************************************************************************************************************"
    puts ""
  end

  context "Import module from git repo" do
    include_context "Create module from provided git repo", module_name_1, git_ssh_repo_url_1
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name_1
  end

  context "Import module from git repo" do
    include_context "Create module from provided git repo", module_name_2, git_ssh_repo_url_2
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name_2
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name_1
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name_1
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name_2
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name_2
  end

  after(:all) do
    puts "", ""
  end
end