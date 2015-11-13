#!/usr/bin/env ruby
# Test Case 06: Add a versioned component module to assembly that already has a version of that component module added
require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'

component_module_name = 'temp06'
component_module_namespace = 'version'
component_module_fullname = "#{component_module_namespace}:#{component_module_name}"
component_module_versions = ['0.0.1', '0.0.2']
component_module_source = "./modules/#{component_module_name}"
component_module_filesystem_location = "~/dtk/component_modules/#{component_module_namespace}"

service_module_name = 'bootstrap'
service_module_namespace = 'version'
assembly_template = 'test1'
assembly_name = "#{service_module_name}::#{assembly_template}"
service_name = 'csv_test_case_05_instance'
new_service_name = 'csv_test_case_05_instance_new'
new_assembly = 'csv_test_case_05_assembly'
node_name = 'test1'



dtk_common = Common.new(service_name, "#{assembly_name}")
dtk_common_new = Common.new(new_service_name, "#{service_module_name}::#{new_assembly}")


describe '(Component, service and versioning) Test Case 06: Add a versioned component module to assembly that already has a version of that component module added'  do
	before :all do
    	puts '*********************************************************************************************************************************', ''
	end

	context "Stage service function on #{assembly_name} assembly" do
    	include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    	include_context 'List services after stage', dtk_common
  end

  context 'Add first component module version to the service' do
  	include_context 'Add versioned component to service', dtk_common, component_module_namespace, component_module_name, component_module_versions[0], service_name, node_name
  end

  context 'Create new assembly from existing service' do
    include_context 'Create assembly from service', dtk_common, service_module_name, new_assembly, service_module_namespace
  end

  context 'Delete and destroy service function' do
    include_context 'Delete services', dtk_common
  end

  context "Stage new service function on #{assembly_name} assembly" do
   	include_context 'Stage', dtk_common_new
  end

  context 'Add second component module version to the new service' do
    include_context 'NEG - Add versioned component to service', dtk_common, component_module_namespace, component_module_name, component_module_versions[1], service_name, node_name
  end

  context 'Delete and destroy service function' do
   	include_context 'Delete services', dtk_common_new
  end

  context 'Delete assembly function' do
   	include_context 'Delete assembly', dtk_common_new, "#{service_module_name}/#{new_assembly}", service_module_namespace
  end

  after(:all) do
   	puts '', ''
  end
end