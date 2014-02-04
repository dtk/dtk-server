#!/usr/bin/env ruby
#Test Case 4: Rename and converge assembly
#Test Case 6: NEG - Rename assembly to the workspace name

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'

STDOUT.sync = true

assembly_name_1 = 'stda_test_case_4_instance'
assembly_name_1_rename = 'stda_test_case_4_instance_rename'
assembly_template = 'bootstrap::test1'

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name_1, assembly_template)

describe "(Staging And Deploying Assemblies) Test Case 4 6: Renaming assembly and renaming it to workspace" do

	before(:all) do
		puts "************************************************************************************************"
		puts "(Staging And Deploying Assemblies) Test Case 4 6: Renaming assembly and renaming it to workspace"
		puts "************************************************************************************************"
		puts ""
	end

	context "Stage assembly function on #{assembly_template} assembly template" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do
		include_context "List assemblies after stage", dtk_common
	end

	context "Rename assembly" do
		include_context "Rename assembly", dtk_common, assembly_name_1_rename
	end

	context "NEG - Rename assembly to workspace name" do
		include_context "NEG - Rename assembly to workspace name", dtk_common, "workspace"
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end