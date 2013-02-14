#!/usr/bin/env ruby
#Test Case 8: (OS: RedHat, Namenode: BigTop) Check possibility to add OS and namenode components and deploy assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './test/lib/dtk_common'
require './test/lib/shared_spec'

STDOUT.sync = true

ASSEMBLY_NAME = 'test_case_8_instance'
ASSEMBLY_TEMPLATE = 'bakir_test::redhat_bigtop_namenode'
namenode_port = 8020
namenode_web_port = 50070

$assembly_id = 0
dtk_common = DtkCommon.new(ASSEMBLY_NAME, ASSEMBLY_TEMPLATE)

describe "Test Case 8: (OS: RedHat, Namenode: BigTop) Check possibility to add OS and namenode components and deploy assembly" do

	context "Stage assembly function" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Namenode port #{namenode_port}" do
		include_context "Check if port avaliable", dtk_common, namenode_port
	end

	context "Namenode web port #{namenode_web_port}" do
		include_context "Check if port avaliable", dtk_common, namenode_web_port
	end

	context "Delete and destroy assemblies" do
		include_context "Delete assemblies", dtk_common
	end
end