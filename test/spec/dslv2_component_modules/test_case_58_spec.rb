#!/usr/bin/env ruby
#Test Case 58: NEG - Ill-formed json content (component instead of components) in dtk.model.json file and push-clone-changes to server

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/modules_spec'

module_name = 'temp'
module_filesystem_location = "~/dtk/component_modules"
file_for_change_location = "./spec/dslv2_component_modules/resources/test_case_58_dtk.model.json"
file_for_change = "dtk.model.json"
dtk_common = DtkCommon.new('', '')

describe "Test Case 58: NEG - Ill-formed json content (component instead of components) in dtk.model.json file and push-clone-changes to server" do

  before(:all) do
    puts "*************************************************************************************************************************************"
    puts "Test Case 58: NEG - Ill-formed json content (component instead of components) in dtk.model.json file and push-clone-changes to server"
    puts "*************************************************************************************************************************************"
  end

  context "Import module function" do
    include_context "Import remote module", module_name
  end

  context "Upgrade module to DSLv2" do
    it "upgrades #{module_name} module to DSLv2" do
      puts "DSLv2 upgrade:", "---------------------"
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

  context "Replace components with component property in dtk.model.json file" do
    include_context "Replace dtk.model.json file with new one", module_name, file_for_change_location, file_for_change, module_filesystem_location, "sets incorrect value - component instead of components in dtk.model.json"
  end

  context "Push clone changes of module from local copy to server" do
    it "pushes module changes from local filesystem to server but fails because of missing components section" do
      fail = false
      value = `dtk module #{module_name} push-clone-changes`
      fail = value.include?("[ERROR] component dsl parsing error: missing key (components)")
      fail.should eq(true)  
    end
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
