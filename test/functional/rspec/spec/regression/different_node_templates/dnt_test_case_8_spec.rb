#!/usr/bin/env ruby
# Test Case 8: Wordpress - Single node scenario

require 'rubygems'
require 'net/http'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'dnt_test_case_8_instance'
assembly_name = 'wordpress_test::wordpress_single_node'
wordpress_app_port = 9000
wordpress_db_port = 3306

node_name = 'node1'
puppet_log_location = '/var/log/puppet/last.log'
puppet_grep_pattern = 'transaction'

dtk_common = DtkCommon.new(service_name, assembly_name)

def get_node_ec2_public_dns(service_name, node_name)
	puts "Get node ec2 public dns:", "------------------------"
	node_ec2_public_dns = ""
	dtk_common = DtkCommon.new('','')

	info_response = dtk_common.send_request('/rest/assembly/info_about', assembly_id: service_name, subtype: :instance, about: "nodes")
	ap info_response

	node_info = info_response['data'].find { |x| x['display_name'] == node_name}

	if !node_info.nil?
		node_ec2_public_dns = node_info['external_ref']['ec2_public_address']
		if !node_ec2_public_dns.nil?
			puts "Node ec2 public dns found!"
			puts ""
			return node_ec2_public_dns
		end
	else
		puts "Info about #{node_name} node is not found!"
		puts ""
		return node_ec2_public_dns
	end	
end

describe "(Different Node Templates) Test Case 8: Wordpress - Single node scenario" do
	before(:all) do
		puts "************************************************************************",""
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

	#context "Grep command on puppet log" do
	#	include_context "Grep log command", dtk_common, node_name, puppet_log_location, puppet_grep_pattern
	#end

	#context "Wordpress app port #{wordpress_app_port}" do
	#	include_context "Check if port avaliable", dtk_common, wordpress_app_port
	#end

	#context "Wordpress db port #{wordpress_db_port}" do
	#	include_context "Check if port avaliable", dtk_common, wordpress_db_port
	#end

	context "Check if wordpress page is up" do
		it "checks that wordpress page is up and running" do
			puts "Check wordpress page is up and running", "--------------------------------------"
			node_ec2_public_dns = get_node_ec2_public_dns(service_name, node_name)
			wordpress_html_output = Net::HTTP.get(node_ec2_public_dns, '/wp-admin/install.php')
			wordpress_regex = /Welcome to the famous five minute WordPress installation process!/
			match = wordpress_html_output.match(wordpress_regex)
			puts ""
			match.should_not eq(nil)
		end
	end

	context "Delete and destroy service function" do
		include_context "Delete services", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end