#!/usr/bin/env ruby
#Test Case 68: Import module from r8 repo and export to default tenant namespace

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

namespace = "bakir"
module_name = "apache"
module_filesystem_location = "~/component_modules"
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "Test Case 68: Import module from r8 repo and export to default tenant namespace" do

  before(:all) do
    puts "*******************************************************************************"
    puts "Test Case 68: Import module from r8 repo and export to default tenant namespace"
    puts "*******************************************************************************"
  end

  context "Import module function" do
    include_context "Import remote module", module_name
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, module_name
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Export module to new namespace" do
    include_context "Export module", dtk_common, module_name, namespace
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end

  context "Delete module from remote" do
    include_context "Delete module from remote repo", dtk_common, module_name, namespace
  end

  after(:all) do
    puts "", ""
  end
end