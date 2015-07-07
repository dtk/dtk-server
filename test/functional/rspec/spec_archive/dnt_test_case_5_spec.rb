#!/usr/bin/env ruby
# Test Case 5: Stage node template, add rsync component, set attribute value, converge it and then check get-netstats, get-ps and list-task-info

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/node_operations_spec'

STDOUT.sync = true

node_name = 'precise-micro'
staged_node_name = 'dnt_test_case_5_instance'
component_name = 'rsync'

dtk_common = DtkCommon.new('', '')

describe "(Different Node Templates) Test Case 5: Stage node template, add rsync component, set attribute value, converge it and then check get-netstats and list-task-info" do
  before(:all) do
    puts "*****************************************************************************************************************************************************************"
    puts "(Different Node Templates) Test Case 5: Stage node template, add rsync component, set attribute value, converge it and then check get-netstats and list-task-info"
    puts "*****************************************************************************************************************************************************************"
    puts ""
  end

  context "Stage node template #{node_name} with name #{staged_node_name}" do
    include_context "Stage node template", dtk_common, node_name, staged_node_name
  end

  context "List nodes after stage" do
    include_context "List nodes after stage", dtk_common, staged_node_name
  end   

  context "Add component to node function" do
    include_context "Add component to node", dtk_common, staged_node_name, component_name
  end

  context "Converge node function" do
    include_context "Converge node", dtk_common, staged_node_name
  end

  context "Check get-netstats output" do
    include_context "get-netstats function on node", dtk_common, staged_node_name, 22
  end

  context "Check list-task-info output" do
    include_context "list-task-info function on node", dtk_common, staged_node_name, component_name
  end
  
  context "Delete and destroy node function" do
    include_context "Destroy node", dtk_common, staged_node_name
  end

  after(:all) do
    puts "", ""
  end
end