#!/usr/bin/env ruby
#Test Case 2: Stage existing assembly and then delete assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './test/lib/dtk_common'
require './test/lib/shared_spec'

STDOUT.sync = true

ASSEMBLY_NAME = 'test_case_2_instance'
ASSEMBLY_TEMPLATE = 'bootstrap::node_with_params'

$assembly_id = 0
dtk_common = DtkCommon.new(ASSEMBLY_NAME, ASSEMBLY_TEMPLATE)

describe "Test Case 2: Stage existing assembly and then delete assembly" do

	context "Stage assembly function" do
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
end