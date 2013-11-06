#!/usr/bin/env ruby
#Test Case 22: Ability to list attributes that belong only to specific component in module

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/modules_spec'

module_name = "apache"
component_name = "apache"
module_namespace = "r8"
module_filesystem_location = "~/dtk/component_modules"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 22: Ability to list attributes that belong only to specific component in module" do

  before(:all) do
    puts "****************************************************************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 22: Ability to list attributes that belong only to specific component in module"
    puts "****************************************************************************************************************************"
    puts ""
  end

  context "Import module function" do
    include_context "Import remote module", module_namespace + "/" + module_name
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, module_name
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Get module attributes list for #{component_name} component" do
    include_context "Get module attributes list by component", dtk_common, module_name, component_name
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