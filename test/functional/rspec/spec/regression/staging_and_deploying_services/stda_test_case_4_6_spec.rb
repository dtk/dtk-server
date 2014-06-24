#!/usr/bin/env ruby
# Test Case 4: Rename and converge service
# Test Case 6: NEG - Rename service to the workspace name

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name_1 = 'stda_test_case_4_instance'
service_name_1_rename = 'stda_test_case_4_instance_rename'
assembly_name = 'bootstrap::test1'
dtk_common = DtkCommon.new(service_name_1, assembly_name)

describe "(Staging And Deploying Assemblies) Test Case 4 6: Renaming service and renaming it to workspace" do

	before(:all) do
		puts "***********************************************************************************************"
		puts "(Staging And Deploying Assemblies) Test Case 4 6: Renaming service and renaming it to workspace"
		puts "***********************************************************************************************"
		puts ""
	end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage", dtk_common
	end

	context "List services after stage" do
		include_context "List services after stage", dtk_common
	end

	context "Rename service" do
		include_context "Rename service", dtk_common, service_name_1_rename
	end

	context "NEG - Rename service to workspace name" do
		include_context "NEG - Rename service to workspace name", dtk_common, service_name_1_rename
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Delete and destroy service function" do
		include_context "Delete services", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end