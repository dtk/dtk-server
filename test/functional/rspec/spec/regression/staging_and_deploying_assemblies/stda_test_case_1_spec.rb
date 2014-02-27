#!/usr/bin/env ruby
#Test Case 1: Stage existing assembly and then delete assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'

STDOUT.sync = true

assembly_name = 'stda_test_case_1_instance'
assembly_template = 'bootstrap::node_with_params'
dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Staging And Deploying Assemblies) Test Case 1: Stage existing assembly and then delete assembly" do

	before(:all) do
		puts "************************************************************************************************"
		puts "(Staging And Deploying Assemblies) Test Case 1: Stage existing assembly and then delete assembly"
		puts "************************************************************************************************"
		puts ""
  	end

	context "Stage assembly function on #{assembly_template} assembly template" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Delete and destroy assemblies function" do
		include_context "Delete assemblies", dtk_common
	end

	context "List assemblies after delete" do
		include_context "List assemblies after delete", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end