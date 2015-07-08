#!/usr/bin/env ruby
# Test Case 8: Stage complex node group example, list nodes, delete nodes, check cardinality, list nodes/components/attributes after delete

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'stda_test_case_8_instance'
assembly_name = 'node_group_test::complex'
node_name = "elements"
nodes = ['elements:1','elements:2','single_node']
components = ['elements/stdlib','single_node/java','single_node/stdlib']
expected_cardinality_before_delete = 2
expected_cardinality_after_delete = 1
dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Staging And Deploying Assemblies) Test Case 8: Stage complex node group example, list nodes, delete nodes, check cardinality, list nodes/components/attributes after delete" do
  before(:all) do
    puts "****************************************************************************************************************************************************************************",""
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context "Stage", dtk_common
  end

  context "List services after stage" do
    include_context "List services after stage", dtk_common
  end

  context "List node on #{service_name} service" do
    include_context "List nodes", dtk_common, nodes
  end

  context "List components on #{service_name} service" do
    include_context "List components", dtk_common, components
  end

  context "Check cardinality on #{service_name} service" do
    include_context "Get cardinality", dtk_common, node_name, expected_cardinality_before_delete
  end

  context "Delete node on #{service_name} service" do
    include_context "Delete node", dtk_common, nodes[0]
  end

  context "Check cardinality on #{service_name} service" do
    include_context "Get cardinality", dtk_common, node_name, expected_cardinality_after_delete
  end

  context "Delete node on #{service_name} service" do
    include_context "Delete node", dtk_common, nodes[1]
  end

  context "Delete node on #{service_name} service" do
    include_context "Delete node", dtk_common, nodes[2]
  end

  context "List node on #{service_name} service" do
    include_context "List nodes", dtk_common, []
  end

  context "List components on #{service_name} service" do
    include_context "List components", dtk_common, []
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
