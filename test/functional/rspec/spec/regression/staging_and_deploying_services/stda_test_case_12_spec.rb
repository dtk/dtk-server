#!/usr/bin/env ruby
# Test Case 12: Ability to add and delete components on assembly level and set their attributes

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/node_operations_spec'

STDOUT.sync = true

service_name = 'stda_test_case_12_instance'
assembly_name = 'bootstrap::test1'
node_name = 'test1'
component_name = 'r8:ruby'
components = ['ruby','test1/ruby']
attribute_name = 'ruby/version'
attribute_value = '2.1.2'
dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Staging And Deploying Assemblies) Test Case 12: Ability to add and delete components on assembly level and set their attributes" do
  before(:all) do
    puts "********************************************************************************************************************************",""
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context "Stage", dtk_common
  end

  context "List services after stage" do
    include_context "List services after stage", dtk_common
  end

  context "Add components to service instance" do
    include_context "Add specific component to service instance", dtk_common, component_name
  end

  context "Add components to service node" do
    include_context "Add specific component to service node", dtk_common, node_name, component_name
  end

  context "List components on #{service_name} service" do
    include_context "List components", dtk_common, components
  end

  context "Set attribute on service level component" do
    include_context "Set attribute on service level component", dtk_common, attribute_name, attribute_value
  end

  context "Set attribute on node level component" do
    include_context "Set attribute", dtk_common, attribute_name, attribute_value
  end

  context "Delete component from service instance" do
    include_context "Delete component from service", dtk_common, nil, components[0]
  end

  context "Delete component from service node" do
    include_context "Delete component from service", dtk_common, node_name, components[0]
  end

  context "Delete and destroy service function" do
    include_context "Delete services", dtk_common
  end

  context "List services after delete" do
    include_context "List services after delete", dtk_common
  end

  after(:all) do
    puts "", ""
  end
end
