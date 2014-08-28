#!/usr/bin/env ruby
# Test Case 1: Stage existing assembly and then delete service

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'stda_test_case_1_instance'
assembly_name = 'bootstrap::node_with_params'
dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Staging And Deploying Assemblies) Test Case 1: Stage existing assembly and then delete service" do

	before(:all) do
		puts "************************************************************************************************",""
  end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage", dtk_common
	end

	context "List services after stage" do		
		include_context "List services after stage", dtk_common
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