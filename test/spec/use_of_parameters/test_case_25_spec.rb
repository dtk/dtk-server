#!/usr/bin/env ruby
#Test Case 25: Check possibility to query list of nodes/components/attributes of particular assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/shared_spec'

$assembly_name = 'test_case_25_instance'
$assembly_template = 'bootstrap::node_with_params'
OS = 'natty'
MEMORY_SIZE = 't1.micro'
NODE_NAME = 'node1'

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

	context "Stage assembly function" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Set OS attribute function" do
		include_context "Set attribute", dtk_common, 'os_identifier', OS
	end

	context "Set MEMORY_SIZE attribute function" do
		include_context "Set attribute", dtk_common, 'memory_size', MEMORY_SIZE
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Node params check function" do
		unless $assembly_id.nil?
			it "checks if node parameters exist on particular node" do
				param_existance = check_param_existance_on_node($assembly_id, NODE_NAME, node_param_list)
				param_existance.should eq(true)
				puts "All params checked on node."
			end
		end
	end

	context "Check type param after converge function" do
		include_context "Check param", dtk_common, NODE_NAME, 'type', 'instance'
	end

	context "Check os_type param after converge function" do
		include_context "Check param", dtk_common, NODE_NAME, 'os_type', 'ubuntu'
	end

	context "Check memory size param after converge function" do
		include_context "Check param", dtk_common, NODE_NAME, 'external_ref', MEMORY_SIZE
	end

	context "Check component on node function" do
		include_context "Check component", dtk_common, NODE_NAME, 'stdlib'
	end

	context "Attribute params check function" do
		unless $assembly_id.nil?
			it "checks if attrubute parameters exist" do
				param_existance = check_param_existance_on_attribute($assembly_id, NODE_NAME, attr_param_list)
				param_existance.should eq(true)
				puts "All attribute params checked."
			end
		end
	end

	context "Check OS attribute after converge function" do
		include_context "Check attribute", dtk_common, NODE_NAME, 'os_identifier', OS
	end

	context "Check MEMORY_SIZE attribute after converge function" do
		include_context "Check attribute", dtk_common, NODE_NAME, 'memory_size', MEMORY_SIZE
	end

	#context "Delete and destroy assemblies" do
#		include_context "Delete assemblies", dtk_common
#	end
end