#!/usr/bin/env ruby
# Test Case 3: Deploy from assembly (stage and converge), stop the running instance (nodes) and then delete service

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'

STDOUT.sync = true

service_name = 'stda_test_case_3_instance'
assembly_name = 'bootstrap::node_with_params'
os = 'precise'
os_attribute = 'os_identifier'
memory_size = 't1.micro'
memory_size_attribute = 'memory_size'
dtk_common = Common.new(service_name, assembly_name)

describe "(Staging And Deploying Assemblies) Test Case 3: Deploy from assembly (stage and converge), stop the running instance (nodes) and then delete service" do

	before(:all) do
		puts "****************************************************************************************************************************************************",""
	end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage", dtk_common
	end

	context "List services after stage" do
		include_context "List services after stage", dtk_common
	end

	context "Set os attribute function" do
		include_context "Set attribute", dtk_common, os_attribute, os
	end

	context "Set Memory attribute function" do
		include_context "Set attribute", dtk_common, memory_size_attribute, memory_size
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Stop service function" do
		include_context "Stop service", dtk_common
	end	

	context "Delete and destroy service function" do
		include_context "Delete services", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end