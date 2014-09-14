#!/usr/bin/env ruby
# Test Case 16: NEG - Import component module from incorrect git repo url

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
git_ssh_repo_url = "git@github.com:puppetlabs/puppetlabs-tftp.git-incorrect"
local_component_module_name = "local:tftp"
component_module_filesystem_location = "~/dtk/component_modules"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 16: NEG - Import component module from incorrect git repo url" do

  before(:all) do
    puts "**********************************************************************************************************",""
  end

  context "Import component module from incorrect git repo" do
    include_context "NEG - Import component module from provided git repo", component_module_name, git_ssh_repo_url
  end

  context "Get component module components list" do
    include_context "NEG - Get component module components list", dtk_common, local_component_module_name
  end

  after(:all) do
    puts "", ""
  end
end