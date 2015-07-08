#!/usr/bin/env ruby
# Test Case 12: Create one node, add component in it, converge workspace and grep puppet log from node

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'

STDOUT.sync = true

node_name = 'test'
node_template = 'precise-micro'
component_name = 'stdlib'
component_module_namespace = 'r8'
puppet_log_location = '/var/log/puppet/last.log'
grep_pattern = 'transaction'

dtk_common = DtkCommon.new('', '')

describe "(Workspace) Test Case 12: Create one node, add component in it, converge workspace and grep puppet log from node" do
  before(:all) do
    puts "****************************************************************************************************************",""
  end

  context "Create node in workspace" do
    include_context "Create node in workspace", dtk_common, node_name, node_template
  end

  context "Add component to the node in workspace" do
    include_context "Add component to the node in workspace", dtk_common, node_name, component_name, component_module_namespace
  end

  context "Converge workspace" do
    include_context "Converge workspace", dtk_common
  end

  context "Grep command on puppet log" do
    include_context "Grep log command", dtk_common, node_name, puppet_log_location, grep_pattern
  end

  context "Purge workspace content" do
    include_context "Purge workspace content", dtk_common
  end

  after(:all) do
    puts "", ""
  end
end
