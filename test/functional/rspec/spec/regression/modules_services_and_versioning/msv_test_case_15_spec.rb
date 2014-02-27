#!/usr/bin/env ruby
#Test Case 15: Import module from git repo url

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

module_name = "tftp"
git_ssh_repo_url = "git@github.com:puppetlabs/puppetlabs-tftp.git"
module_filesystem_location = "~/dtk/component_modules"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 15: Import module from git repo url" do

  before(:all) do
    puts "********************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 15: Import module from git repo url"
    puts "********************************************************************************"
    puts ""
  end

  context "Create module from git repo" do
    include_context "Create module from provided git repo", module_name, git_ssh_repo_url
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