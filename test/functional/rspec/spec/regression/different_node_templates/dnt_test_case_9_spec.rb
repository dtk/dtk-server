#!/usr/bin/env ruby
#Test Case 9: Redis - Master/Slave scenario

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'

STDOUT.sync = true

$assembly_id = 0
assembly_name = 'dnt_test_case_9_instance'
assembly_template = 'redis_test::redis_master_slave'
redis_port = 6379

node_name_1 = 'master'
node_name_2 = 'slave'
puppet_log_location = '/var/log/puppet/last.log'
puppet_grep_pattern = 'transaction'

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Different Node Templates) Test Case 9: Redis - Master/Slave scenario" do

	before(:all) do
		puts "*********************************************************************"
		puts "(Different Node Templates) Test Case 9: Redis - Master/Slave scenario"
		puts "*********************************************************************"
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

	context "Grep command on puppet log on redis master instance" do
		include_context "Grep log command", dtk_common, node_name_1, puppet_log_location, puppet_grep_pattern
	end

	context "Grep command on puppet log on redis slave instance" do
		include_context "Grep log command", dtk_common, node_name_2, puppet_log_location, puppet_grep_pattern
	end

	context "Redis master instance port #{redis_port}" do
		include_context "Check if port avaliable on specific node", dtk_common, node_name_1, redis_port
	end

	context "Redis slave instance port #{redis_port}" do
		include_context "Check if port avaliable on specific node", dtk_common, node_name_2, redis_port
	end

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end