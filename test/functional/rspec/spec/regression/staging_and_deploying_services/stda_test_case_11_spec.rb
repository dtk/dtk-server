#!/usr/bin/env ruby
# Test Case 11: Stage multi node assembly, try to grant access and revoke non-existing access, converge assembly and then try grant and revoke access again

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'stda_test_case_11_instance'
assembly_name = 'multinode_test::test1'
nodes = ['test1','test2']
system_user = 'ubuntu'
rsa_pub_name = 'test'
dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Staging And Deploying Assemblies) Test Case 11: Stage multi node assembly, try to grant access and revoke non-existing access, converge assembly and then try grant and revoke access again" do

	before(:all) do
		puts "********************************************************************************************************************************************************************************************",""
  end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage", dtk_common
	end

	context "List services after stage" do		
		include_context "List services after stage", dtk_common
	end

	context "Grant access before converge" do
		include_context "NEG - Grant access before converge", dtk_common, system_user, rsa_pub_name
	end

	context "List ssh access and confirm is empty" do
		include_context "List ssh access and confirm is empty", dtk_common, system_user, rsa_pub_name, nodes
	end

	context "Revoke access before converge" do
		include_context "NEG - Revoke access before converge", dtk_common, system_user, rsa_pub_name
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Grant access after converge" do
		include_context "Grant access after converge", dtk_common, system_user, rsa_pub_name
	end

	context "List ssh access" do
		include_context "List ssh access", dtk_common, system_user, rsa_pub_name, nodes
	end

	context "Revoke access after converge" do
		include_context "Revoke access after converge", dtk_common, system_user, rsa_pub_name
	end

	context "List ssh access and confirm is empty" do
		include_context "List ssh access and confirm is empty", dtk_common, system_user, rsa_pub_name, nodes
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
