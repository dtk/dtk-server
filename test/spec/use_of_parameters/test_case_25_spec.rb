#!/usr/bin/env ruby
#Test Case 25: Check possibility to query list of nodes/components/attributes of particular assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec.rb'

$assembly_name = 'test_case_25_instance'
$assembly_template = 'bootstrap::node_with_params'
os = 'natty'
memory_size = 't1.micro'
node_name = 'node1'

node_param_list = Array.new
node_param_list << 'dns_name'
node_param_list << 'ec2_public_address'
node_param_list << 'private_dns_name'

attr_param_list = Array.new
attr_param_list << 'memory_size'
attr_param_list << 'os_identifier'

$assembly_id = 0
dtk_common = DtkCommon.new($assembly_name, $assembly_template)

def check_param_existance_on_node(assembly_id, node_name, param_name_list)
	dtk_common = DtkCommon.new($assembly_name, $assembly_template)
	param_check = true
	assembly_nodes = dtk_common.send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'nodes', :subtype=>'instance'})

	content = assembly_nodes['data'].select { |x| x['display_name'] == node_name }
	dtk_common.pretty_print_JSON(content)

	if (!content.empty?)
		param_name_list.each do |param_name_to_check|
 			if (content.first['external_ref'].include? param_name_to_check)
				puts "Parameter with name #{param_name_to_check} exists"
				param_check = true
			else
				puts "Parameter with name #{param_name_to_check} does not exist"
				param_check = false
				break
			end
		end
	else
		puts "Content empty!. Param check not possible"
		param_check
	end

	return param_check
end

def check_param_existance_on_attribute(assembly_id, node_name, param_name_list)
	dtk_common = DtkCommon.new($assembly_name, $assembly_template)
	param_check = true
	assembly_attributes = dtk_common.send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'attributes', :subtype=>'instance'})

	param_name_list.each do |param_name_to_check|
		content = assembly_attributes['data'].select { |x| x['display_name'].include? "node[#{node_name}]/#{param_name_to_check}" }
		dtk_common.pretty_print_JSON(content)
 		if (!content.empty?)
			puts "Parameter with name #{param_name_to_check} exists"
			param_check = true
		else
			puts "Parameter with name #{param_name_to_check} does not exist"
			param_check = false
			break
		end
	end

	return param_check
end

describe "Test Case 25: Check possibility to query list of nodes/components/attributes of particular assembly" do

	before(:all) do
		puts "***************************************************************************************************"
		puts "Test Case 25: Check possibility to query list of nodes/components/attributes of particular assembly"
		puts "***************************************************************************************************"
	end

	context "Stage assembly function on #{$assembly_template} assembly template" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Set os attribute function" do
		include_context "Set attribute", dtk_common, 'os_identifier', os
	end

	context "Set memory_size attribute function" do
		include_context "Set attribute", dtk_common, 'memory_size', memory_size
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Node params check function" do
		it "checks if all node parameters (dns_name, ec2_public_address, private_dns_name) exist on node #{node_name}" do
			param_existance = check_param_existance_on_node($assembly_id, node_name, node_param_list)
			param_existance.should eq(true)
		end
	end

	context "Check type param after converge" do
		include_context "Check param", dtk_common, node_name, 'type', 'instance'
	end

	context "Check os_type param after converge" do
		include_context "Check param", dtk_common, node_name, 'os_type', 'ubuntu'
	end

	context "Check memory size param after converge" do
		include_context "Check param", dtk_common, node_name, 'external_ref', memory_size
	end

	context "Check component on node" do
		include_context "Check component", dtk_common, node_name, 'stdlib'
	end

	context "Attribute params check function" do
		it "checks if all attribute parameters (memory_size, os_identifier) exist on node #{node_name}" do
			param_existance = check_param_existance_on_attribute($assembly_id, node_name, attr_param_list)
			param_existance.should eq(true)
		end
	end

	context "Check os attribute after converge" do
		include_context "Check attribute", dtk_common, node_name, 'os_identifier', os
	end

	context "Check memory_size attribute after converge" do
		include_context "Check attribute", dtk_common, node_name, 'memory_size', memory_size
	end

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end