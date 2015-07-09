#!/usr/bin/env ruby
# Test Case 6: Check possibility to query list of nodes/components/attributes of particular service

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'

service_name = 'uop_test_case_6_instance'
assembly_name = 'bootstrap::node_with_params'
os = 'precise'
memory_size = 't1.micro'
node_name = 'node1'

node_param_list = []
node_param_list << 'dns_name'
node_param_list << 'ec2_public_address'
node_param_list << 'private_dns_name'

attr_param_list = []
attr_param_list << 'memory_size'
attr_param_list << 'os_identifier'

dtk_common = DtkCommon.new(service_name, assembly_name)

def check_param_existance_on_node(dtk_common, node_name, param_name_list)
  param_check = true
  service_id = dtk_common.service_id
  service_nodes = dtk_common.send_request('/rest/assembly/info_about', assembly_id: service_id, filter: nil, about: 'nodes', subtype: 'instance')

  content = service_nodes['data'].select { |x| x['display_name'] == node_name }
  ap content

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
    puts 'Content empty!. Param check not possible'
    param_check
  end

  return param_check
end

def check_param_existance_on_attribute(dtk_common, node_name, param_name_list)
  param_check = true
  service_id = dtk_common.service_id
  service_attributes = dtk_common.send_request('/rest/assembly/info_about', assembly_id: service_id, filter: nil, about: 'attributes', subtype: 'instance')

  param_name_list.each do |param_name_to_check|
    content = service_attributes['data'].select { |x| x['display_name'].include? "#{node_name}/#{param_name_to_check}" }
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

describe '(Use Of Parameters) Test Case 6: Check possibility to query list of nodes/components/attributes of particular service' do
  before(:all) do
    puts '*********************************************************************************************************************', ''
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Set os attribute function' do
    include_context 'Set attribute', dtk_common, 'os_identifier', os
  end

  context 'Set memory_size attribute function' do
    include_context 'Set attribute', dtk_common, 'memory_size', memory_size
  end

  context 'Converge function' do
    include_context 'Converge', dtk_common
  end

  context 'Node params check function' do
    it "checks if all node parameters (dns_name, ec2_public_address, private_dns_name) exist on node #{node_name}" do
      puts 'Check node params', '-----------------'
      param_existance = check_param_existance_on_node(dtk_common, node_name, node_param_list)
      puts ''
      param_existance.should eq(true)
    end
  end

  context 'Check type param after converge' do
    include_context 'Check param', dtk_common, node_name, 'type', 'instance'
  end

  context 'Check os_type param after converge' do
    include_context 'Check param', dtk_common, node_name, 'os_type', 'ubuntu'
  end

  context 'Check memory size param after converge' do
    include_context 'Check param', dtk_common, node_name, 'external_ref', memory_size
  end

  context 'Check component on node' do
    include_context 'Check component', dtk_common, node_name, 'stdlib'
  end

  context 'Attribute params check function' do
    it "checks if all attribute parameters (memory_size, os_identifier) exist on node #{node_name}" do
      puts 'Check attribute params', '----------------------'
      param_existance = check_param_existance_on_attribute(dtk_common, node_name, attr_param_list)
      puts ''
      param_existance.should eq(true)
    end
  end

  context 'Check os attribute after converge' do
    include_context 'Check attribute', dtk_common, node_name, 'os_identifier', os
  end

  context 'Check memory_size attribute after converge' do
    include_context 'Check attribute', dtk_common, node_name, 'memory_size', memory_size
  end

  context 'Delete and destroy service function' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
