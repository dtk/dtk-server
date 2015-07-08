#!/usr/bin/env ruby
# Test Case 5: Create two nodes (list nodes), delete one node (list nodes again) and purge workspace content

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'

STDOUT.sync = true

node_name_1 = 'test1'
node_name_2 = 'test2'
node_template = 'precise-micro'

dtk_common = DtkCommon.new('', '')

describe "(Workspace) Test Case 5: Create two nodes (list nodes), delete one node (list nodes again) and purge workspace content" do
  before(:all) do
    puts "**********************************************************************************************************************",""
  end

  context "Create node in workspace" do
    include_context "Create node in workspace", dtk_common, node_name_1, node_template
  end

  context "Create node in workspace" do
    include_context "Create node in workspace", dtk_common, node_name_2, node_template
  end

  context "Check node in workspace" do
    include_context "Check node in workspace", dtk_common, node_name_1
  end

  context "Check node in workspace" do
    include_context "Check node in workspace", dtk_common, node_name_2
  end

  context "Delete node in workspace" do
    include_context "Delete node in workspace", dtk_common, node_name_1
  end

  context "NEG - Check node in workspace" do
    include_context "NEG - Check node in workspace", dtk_common, node_name_1
  end

  context "Check node in workspace" do
    include_context "Check node in workspace", dtk_common, node_name_2
  end

  context "Purge workspace content" do
    include_context "Purge workspace content", dtk_common
  end

  after(:all) do
    puts "", ""
  end
end
