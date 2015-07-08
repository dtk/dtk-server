#!/usr/bin/env ruby
# Test Case 22: Ability to list attributes that belong only to specific component in component module

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

component_module_name = "apache"
component_name = "apache"
component_module_namespace = "r8"
local_component_module_name = "r8:apache"
component_module_filesystem_location = "~/dtk/component_modules/r8"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 22: Ability to list attributes that belong only to specific component in component module" do
  before(:all) do
    puts "**************************************************************************************************************************************",""
  end

  context "Import component module function" do
    include_context "Import remote component module", component_module_namespace + "/" + component_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, local_component_module_name
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, component_module_name
  end

  context "Get component module attributes list for #{component_name} component" do
    include_context "Get component module attributes list by component", dtk_common, local_component_module_name, component_name
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