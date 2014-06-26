#!/usr/bin/env ruby
# Test Case 2: (OS: CentOS, Namenode: BigTop) Check possibility to add OS and namenode components and deploy assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'dnt_test_case_2_instance'
assembly_name = 'bakir_test::bigtop_namenode'
namenode_port = 8020
namenode_web_port = 50070

dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Different Node Templates) Test Case 2: (OS: CentOS, Namenode: BigTop) Check possibility to add OS and namenode components and deploy assembly" do

	before(:all) do
		puts "**********************************************************************************************************************************************"
		puts "(Different Node Templates) Test Case 2: (OS: CentOS, Namenode: BigTop) Check possibility to add OS and namenode components and deploy assembly"
		puts "**********************************************************************************************************************************************"
		puts ""
  	end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage", dtk_common
	end

	context "List services after stage" do		
		include_context "List services after stage", dtk_common
	end

	context "Converge function" do
		include_context "Converge service", dtk_common, 20
	end

	context "Namenode port #{namenode_port}" do
		include_context "Check if port avaliable", dtk_common, namenode_port
	end

	context "Namenode web port #{namenode_web_port}" do
		include_context "Check if port avaliable", dtk_common, namenode_web_port
	end

	context "Delete and destroy service function" do
		include_context "Delete services", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end