#!/usr/bin/env ruby
#Test Case 49: Rename existing component from dtk.model.json file, push-clone-changes to server and list components to see the effect of rename

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/modules_spec'

module_name = 'temp'
module_namespace = 'r8'
module_filesystem_location = "~/dtk/component_modules"
file_for_change_location = "./spec/dslv2_component_modules/resources/test_case_49_dtk.model.json"
file_for_change = "dtk.model.json"

dtk_common = DtkCommon.new("", "")

describe "Test Case 49: Rename existing component from dtk.model.json file, push-clone-changes to server and list components to see the effect of rename" do

  before(:all) do
    puts "**********************************************************************************************************************************************"
    puts "Test Case 49: Rename existing component from dtk.model.json file, push-clone-changes to server and list components to see the effect of rename"
    puts "**********************************************************************************************************************************************"
    puts ""
  end

  context "Import module function" do
    include_context "Import remote module", module_namespace + "/" + module_name
  end

  context "Upgrade module to DSLv2" do
    it "upgrades #{module_name} module to DSLv2" do
      puts "DSLv2 upgrade:", "--------------"
      pass = false
      value = `dtk module #{module_name} dsl-upgrade`
      pass = true if (value.include? "Status: OK")
      puts "DSLv2 upgrade of module #{module_name} completed successfully!" if pass == true
      puts "DSLv2 upgrade of module #{module_name} did not complete successfully!" if pass == false
      puts ""
      pass.should eq(true)
    end
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, module_name
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Rename existing component in dtk.model.json file" do
    include_context "Replace dtk.model.json file with new one", module_name, file_for_change_location, file_for_change, module_filesystem_location, "renames source component to source2"
  end

  context "Push clone changes of module from local copy to server" do
    include_context "Push clone changes to server", module_name, file_for_change
  end

  context "Check if sink component exists in module" do
    include_context "Check if component exists in module", dtk_common, module_name, "temp::sink"
  end

  context "Check if source2 component exists in module" do
    include_context "Check if component exists in module", dtk_common, module_name, "temp::source2"
  end

  context "Check if source component exists in module after rename" do
    include_context "NEG - Check if component exists in module", dtk_common, module_name, "temp::source"
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

