#!/usr/bin/env ruby
# Test Case 1: Service with one node that contains cmp with actions with multiple commands in it

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'af_test_case_1_instance'
service_module_namespace = "test"
assembly_name = 'action_module::multiple-commands'
dtk_common = DtkCommon.new(service_name, assembly_name)

expected_output_1_1 = {
	:command => "ls /usr",
	:status => 0,
	:stderr => nil,
}

expected_output_1_2 = {
	:command => "ls -l /usr/share/mcollective",
	:status => 0,
	:stderr => nil,
}

expected_output_2_1 = {
	:command => "cat /some/non/existing/file",
	:status => nil,
	:stderr => "cat: /some/non/existing/file: No such file or directory",
}

expected_output_2_2 = {
	:command => "ls -l /some/non/existing/location",
	:status => nil,
	:stderr => "ls: cannot access /some/non/existing/location: No such file or directory"
}

describe "(Action Framework) Test Case 1: Service with one node that contains cmp with actions with multiple commands in it" do

	before(:all) do
		puts "*****************************************************************************************************************",""
  end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage with namespace", dtk_common, service_module_namespace
	end

	context "List services after stage" do		
		include_context "List services after stage", dtk_common
	end

	context "NEG - Converge function" do
		include_context "NEG - Converge", dtk_common
	end

	context "Get task action details for action with two successfull commands" do
		include_context "Get task action details", dtk_common, "3.1", [expected_output_1_1, expected_output_1_2]
	end

	context "Get task action details for action with two failure commands" do
		include_context "Get task action details", dtk_common, "4.1", [expected_output_2_1, expected_output_2_2]
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
