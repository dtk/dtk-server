#!/usr/bin/env ruby
#Test Case 4: Deploy from assembly template (stage and converge), stop the running instance (nodes) and then delete assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec.rb'

STDOUT.sync = true

assembly_name = 'test_case_4_instance'
assembly_template = 'bootstrap::node_with_params'
OS = 'natty'
OS_ATTRIBUTE = 'os_identifier'
MEMORY_SIZE = 't1.micro'
MEMORY_SIZE_ATTRIBUTE = 'memory_size'

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "Test Case 4: Deploy from assembly template (stage and converge), stop the running instance (nodes) and then delete assembly" do

	context "Stage assembly function" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do
		include_context "List assemblies after stage", dtk_common
	end

	context "Set OS attribute function" do
		include_context "Set attribute", dtk_common, OS_ATTRIBUTE, OS
	end

	context "Set Memory attribute function" do
		include_context "Set attribute", dtk_common, MEMORY_SIZE_ATTRIBUTE, MEMORY_SIZE
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Stop assembly function" do
		include_context "Stop assembly", dtk_common
	end	

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end
end