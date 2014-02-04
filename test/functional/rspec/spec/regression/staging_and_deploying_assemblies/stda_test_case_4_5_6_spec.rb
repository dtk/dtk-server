#!/usr/bin/env ruby
#Test Case 4: Rename and converge assembly
#Test Case 5: NEG - Rename assembly to the name that already exist
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
assembly_name_2 = 'stda_test_case_5_instance'
assembly_template = 'bootstrap::test1'

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name_1, assembly_template)
dtk_common2 = DtkCommon.new(assembly_name_2, assembly_template)

describe "(Staging And Deploying Assemblies) Test Case 4 5 6: Renaming assembly (basic case, to the name that already exist, to the workspace name" do

	before(:all) do
		puts "****************************************************************************************************************************************"
		puts "(Staging And Deploying Assemblies) Test Case 4 5 6: Renaming assembly (basic case, to the name that already exist, to the workspace name"
		puts "****************************************************************************************************************************************"
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

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Stage assembly function on #{assembly_template} assembly template" do
		include_context "Stage", dtk_common2
	end	

	context "List assemblies after stage" do
		include_context "List assemblies after stage", dtk_common2
	end

	context "NEG - Rename assembly to existing name" do
		include_context "NEG - Rename assembly to existing name", dtk_common2, assembly_name_2, assembly_name_1
	end

	context "NEG - Rename assembly to workspace name" do
		include_context "NEG - Rename assembly to workspace name", dtk_common2, assembly_name_2
	end

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end