#!/usr/bin/env ruby
#Test Case 3: Fan-in scenario - $node.host_address from sink component are linked to upstream attributes of source components that exist on different nodes (source1, source2)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'

STDOUT.sync = true

assembly_name = 'clr_test_case_3_instance'
assembly_template = 'unit_test::fan_in'
node_name_1 = "source1"
component_name_1 = "unit_test::source"
node_name_2 = "source2"
component_name_2 = "unit_test::source"
dependency_component = 'unit_test::sink'
dependency_satisfied_by = ['sink/unit_test::sink']
value_to_match_1_1 = 'nil'
value_to_match_1_2 = 'nil'
value_to_match_2_1 = 'ec2'
value_to_match_2_2 = 'ec2'
attribute_name = 'upstream'
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Component link relations) Test Case 3: Fan-in scenario - $node.host_address from sink component are linked to upstream attributes of source components that exist on different nodes (source1, source2)" do

  before(:all) do
    puts "********************************************************************************************************************************************************************************************************"
    puts "(Component link relations) Test Case 3: Fan-in scenario - $node.host_address from sink component are linked to upstream attributes of source components that exist on different nodes (source1, source2)"
    puts "********************************************************************************************************************************************************************************************************"
    puts ""
  end

  context "Stage assembly function on #{assembly_template} assembly template" do
    include_context "Stage", dtk_common
  end

  context "List assemblies after stage" do    
    include_context "List assemblies after stage", dtk_common
  end

  context "List component dependencies" do
    include_context "List component dependencies", dtk_common, "#{node_name_1}/#{component_name_1}", dependency_component, dependency_satisfied_by
  end

  context "List component dependencies" do
    include_context "List component dependencies", dtk_common, "#{node_name_2}/#{component_name_2}", dependency_component, dependency_satisfied_by
  end

  context "Get attribute value from component" do
    include_context "Get attribute value from component", dtk_common, node_name_1, component_name_1, attribute_name, value_to_match_1_1
  end

  context "Get attribute value from component" do
    include_context "Get attribute value from component", dtk_common, node_name_2, component_name_2, attribute_name, value_to_match_1_2
  end

  context "Converge function" do
    include_context "Converge", dtk_common
  end

  context "Get attribute value from component" do
    include_context "Get attribute value from component", dtk_common, node_name_1, component_name_1, attribute_name, value_to_match_2_1
  end

  context "Get attribute value from component" do
    include_context "Get attribute value from component", dtk_common, node_name_2, component_name_2, attribute_name, value_to_match_2_2
  end

  context "Delete and destroy assembly function" do
    include_context "Delete assemblies", dtk_common
  end

  after(:all) do
    puts "", ""
  end
end