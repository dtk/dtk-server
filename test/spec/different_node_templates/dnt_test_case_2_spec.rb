#!/usr/bin/env ruby
#Test Case 2: (OS: CentOS, Namenode: BigTop) Check possibility to add OS and namenode components and deploy assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'

STDOUT.sync = true

assembly_name = 'dnt_test_case_2_instance'
assembly_template = 'bakir_test::redhat_bigtop_namenode'
memory = 'm1.small'
namenode_port = 8020
namenode_web_port = 50070
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Different Node Templates) Test Case 2: (OS: CentOS, Namenode: BigTop) Check possibility to add OS and namenode components and deploy assembly" do

	before(:all) do
		puts "**********************************************************************************************************************************************"
		puts "(Different Node Templates) Test Case 2: (OS: CentOS, Namenode: BigTop) Check possibility to add OS and namenode components and deploy assembly"
		puts "**********************************************************************************************************************************************"
		puts ""
  end

	context "Stage assembly function on #{assembly_template} assembly template" do
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

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end