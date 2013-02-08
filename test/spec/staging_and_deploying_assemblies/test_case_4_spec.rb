#!/usr/bin/env ruby
#Test Case 4: Deploy from assembly template (stage and converge), stop the running instance (nodes) and then delete assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './test/lib/dtk_common'
require './test/lib/shared_spec'

STDOUT.sync = true

ASSEMBLY_NAME = 'test_case_4_instance'
ASSEMBLY_TEMPLATE = 'bootstrap::node_with_params'
OS = 'natty'
OS_ATTRIBUTE = 'os_identifier'
MEMORY_SIZE = 't1.micro'
MEMORY_SIZE_ATTRIBUTE = 'memory_size'

$assembly_id = 0
dtk_common = DtkCommon.new(ASSEMBLY_NAME, ASSEMBLY_TEMPLATE)

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