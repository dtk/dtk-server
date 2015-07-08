#!/usr/bin/env ruby
# Test Case 2: Fan-out scenario - $node.host_address from sink components on different nodes (sink1, sink2) are linked to upstream attribute of source component

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'

STDOUT.sync = true

service_name = 'clr_test_case_2_instance'
assembly_name = 'unit_test::fan_out'
node_name = "source"
component_name = "unit_test::source"
namespace = "dtk18"
dependency_component = 'unit_test::sink'
dependency_satisfied_by = ['sink2/unit_test::sink', 'sink1/unit_test::sink']
value_to_match_1 = 'nil, nil'
value_to_match_2 = 'ec2'
attribute_name = 'upstream'

dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Component link relations) Test Case 2: Fan-out scenario - $node.host_address from sink components on different nodes (sink1, sink2) are linked to upstream attribute of source component" do
  before(:all) do
    puts "*****************************************************************************************************************************************************************************************",""
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context "Stage", dtk_common
  end

  context "List services after stage" do
    include_context "List services after stage", dtk_common
  end

  context "List component dependencies" do
    include_context "List component dependencies", dtk_common, "#{node_name}/#{component_name}", dependency_component, dependency_satisfied_by
  end

  context "Get attribute value from component" do
    include_context "Get attribute value from component", dtk_common, node_name, component_name, attribute_name, value_to_match_1
  end

  context "Converge function" do
    include_context "Converge", dtk_common
  end

  context "Get attribute value from component" do
    include_context "Get attribute value from component", dtk_common, node_name, component_name, attribute_name, value_to_match_2
  end

  context "Delete and destroy service function" do
    include_context "Delete services", dtk_common
  end

  after(:all) do
    puts "", ""
  end
end