#!/usr/bin/env ruby
#DTK Server smoke test

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

assembly_name = 'smoke_test_instance'
assembly_template = 'bootstrap::node_with_params'
os = 'precise'
os_attribute = 'os_identifier'
memory_size = 't1.micro'
memory_size_attribute = 'memory_size'

node_name = 'node1'
module_name = "test"
module_namespace = "dtk17"
module_filesystem_location = "~/dtk/component_modules"
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "DTK Server smoke test" do

  before(:all) do
    puts "*********************"
    puts "DTK Server smoke test"
    puts "*********************"
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

  context "Stage assembly function on #{assembly_template} assembly template" do
    include_context "Stage", dtk_common
  end

  context "List assemblies after stage" do    
    include_context "List assemblies after stage", dtk_common
  end

  context "Set os attribute function" do
    include_context "Set attribute", dtk_common, os_attribute, os
  end

  context "Set memory size attribute function" do
    include_context "Set attribute", dtk_common, memory_size_attribute, memory_size
  end

  context "Add components from test module to assembly node" do
    include_context "Add component to assembly node", dtk_common, node_name
  end

  context "Converge function" do
    include_context "Converge", dtk_common
  end

  context "Delete and destroy assembly function" do
    include_context "Delete assemblies", dtk_common
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