#!/usr/bin/env ruby
#Test Case 71: Import module from puppet forge

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

puppet_forge_module_name = "puppetlabs-ruby"
module_name = "ruby"
module_filesystem_location = "~/component_modules"
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "Test Case 71: Import module from puppet forge" do

  before(:all) do
    puts "*********************************************"
    puts "Test Case 71: Import module from puppet forge"
    puts "*********************************************"
  end

  context "Import module from puppet forge" do
    include_context "Import module from puppet forge", puppet_forge_module_name
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, module_name
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