#!/usr/bin/env ruby
#Test Case 3: Add new target to existing provider, stage two assemblies and check list of assemblies that belong to this target

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/target_spec'
require './lib/assembly_operations_spec'

STDOUT.sync = true

assembly_name1 = 'tp_test_case_3_instance_1'
assembly_name2 = 'tp_test_case_3_instance_2'
assembly_template = 'bootstrap::test1'
provider_name = "test_provider-template"
region = "us-east-1"
target_name = "#{provider_name}-#{region}"

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name1, assembly_template)
dtk_common2 = DtkCommon.new(assembly_name2, assembly_template)

describe "(Targets and Providers) Test Case 3: Add new target to existing provider, stage two assemblies and check list of assemblies that belong to this target" do

	before(:all) do
		puts "******************************************************************************************************************************************************"
		puts "(Targets and Providers) Test Case 3: Add new target to existing provider, stage two assemblies and check list of assemblies that belong to this target"
		puts "******************************************************************************************************************************************************"
		puts ""
  	end

	context "Create target command" do
		include_context "Create target", dtk_common, provider_name, region
	end

	context "Target #{provider_name}-#{region}" do		
		include_context "Check if target exists in provider", dtk_common, provider_name, target_name
	end

	context "Stage assembly in specific target" do
    	include_context "Stage assembly in specific target", dtk_common, target_name
  	end

  	context "Assembly #{assembly_name1}" do		
		include_context "Check if assembly exists in target", dtk_common, assembly_name1, target_name
	end  

	context "Stage assembly in specific target" do
    	include_context "Stage assembly in specific target", dtk_common2, target_name
  	end

	context "Assembly #{assembly_name2}" do		
		include_context "Check if assembly exists in target", dtk_common2, assembly_name2, target_name
	end

	context "Delete target command" do
		include_context "Delete target", dtk_common2, target_name
	end

	context "Target #{provider_name}-#{region}" do		
		include_context "NEG - Check if target exists in provider", dtk_common2, provider_name, target_name
	end

	after(:all) do
		puts "", ""
	end
end