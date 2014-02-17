#!/usr/bin/env ruby
#Test Case 12: NEG - Ill-formed yaml content (type: integersss instead of integer) in dtk.model.yaml file and push-clone-changes to server

require 'rubygems'
require 'rest_client'
require 'pp'
require 'awesome_print'
require './lib/dtk_common'
require './lib/modules_spec'

module_name = 'temp'
module_namespace = 'dtk17'
module_filesystem_location = "~/dtk/component_modules"
file_for_change_location = "./spec/regression/dslv3_component_modules/resources/cmd_test_case_12_dtk.model.yaml"
file_for_change = "dtk.model.yaml"
dtk_common = DtkCommon.new('', '')

describe "(Component Module DSL) Test Case 12: NEG - Ill-formed yaml content (type: integersss instead of integer) in dtk.model.yaml file and push-clone-changes to server" do

  before(:all) do
    puts "****************************************************************************************************************************************************************"
    puts "(Component Module DSL) Test Case 12: NEG - Ill-formed yaml content (type: integersss instead of integer) in dtk.model.yaml file and push-clone-changes to server"
    puts "****************************************************************************************************************************************************************"
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

  context "Set incorrect type value to integersss in dtk.model.yaml file" do
    include_context "Replace dtk.model.yaml file with new one", module_name, file_for_change_location, file_for_change, module_filesystem_location, "sets incorrect type value integersss instead of integer in attribute section in dtk.model.yaml"
  end

  context "Push clone changes of module from local copy to server" do
    it "pushes module changes from local filesystem to server but fails because of incorrect type value - integersss" do
      fail = false
      value = `dtk component-module #{module_name} push`
      puts value
      fail = value.include?("error")
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