#!/usr/bin/env ruby
#Test Case 84: Ability to list components and all attributes from the specific module

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/modules_spec'

module_name = "apache"
module_namespace = "r8"
module_filesystem_location = "~/dtk/component_modules"

dtk_common = DtkCommon.new('', '')

describe "Test Case 84: Ability to list components and all attributes from the specific module" do

  before(:all) do
    puts "************************************************************************************"
    puts "Test Case 84: Ability to list components and all attributes from the specific module"
    puts "************************************************************************************"
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

  context "Get module attributes list for all components" do
    include_context "Get module attributes list", dtk_common, module_name, ''
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