#!/usr/bin/env ruby
# Test Case 15: Import component module from git repo url

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'

component_module_name = "tftp"
git_ssh_repo_url = "git@github.com:puppetlabs/puppetlabs-tftp.git"
imported_component_module_name = "local:tftp"
component_module_filesystem_location = "~/dtk/component_modules/local"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 15: Import component module from git repo url" do

  before(:all) do
    puts "*******************************************************************************************",""
  end

  context "Import component module from git repo" do
    include_context "Import component module from provided git repo", component_module_name, git_ssh_repo_url
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, component_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, imported_component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end