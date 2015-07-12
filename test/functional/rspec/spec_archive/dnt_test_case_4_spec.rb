#!/usr/bin/env ruby
# Test Case 4: Stage node template and converge it (simple)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/node_operations_spec'

STDOUT.sync = true

node_name = 'precise-micro'
staged_node_name = 'dnt_test_case_4_instance'

dtk_common = Common.new('', '')

describe "(Different Node Templates) Test Case 4: Stage node template and converge it (simple)" do

  before(:all) do
    puts "************************************************************************************"
    puts "(Different Node Templates) Test Case 4: Stage node template and converge it (simple)"
    puts "************************************************************************************"
    puts ""
  end

  context "Stage node template #{node_name} with name #{staged_node_name}" do
    include_context "Stage node template", dtk_common, node_name, staged_node_name
  end

  context "List nodes after stage" do
    include_context "List nodes after stage", dtk_common, staged_node_name
  end   

  context "Converge node function" do
    include_context "Converge node", dtk_common, staged_node_name
  end
  
  context "Delete and destroy node function" do
    include_context "Destroy node", dtk_common, staged_node_name
  end

  after(:all) do
    puts "", ""
  end
end