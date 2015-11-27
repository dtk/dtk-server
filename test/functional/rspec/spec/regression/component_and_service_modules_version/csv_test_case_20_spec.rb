#!/usr/bin/env ruby
# Test Case 20: Install versioned component module, add it to assembly, stage assembly to service and converge the service

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'

component_module_name = 'temp20'
component_module_namespace = 'version'
component_module_fullname = "#{component_module_namespace}:#{component_module_name}"
component_module_version = '0.0.1'
component_module_source = "./modules/#{component_module_name}"
component_module_filesystem_location = "~/dtk/component_modules/#{component_module_namespace}"

service_module_name = 'temp_service_20'
service_module_namespace = 'version'
service_module_filesystem_location = "~/dtk/component_modules/#{component_module_namespace}"
assembly_template = 'test'
assembly_name = "#{service_module_name}::#{assembly_template}"
service_name = 'csv_test_case_20_instance'
new_service_name = 'csv_test_case_20_instance_new'
new_assembly = 'csv_test_case_20_assembly'
node_name = 'test'

dtk_common = Common.new(service_name, "#{assembly_name}")
dtk_common_new = Common.new(new_service_name, "#{service_module_name}::#{new_assembly}")


describe '(Component, service and versioning) Test Case 20: Install versioned component module, add it to assembly, stage assembly to service and converge the service'  do
	before :all do
    	puts '*********************************************************************************************************************************', ''
	end

	context "Stage service function on #{assembly_name} assembly" do
    	include_context 'Stage', dtk_common
  	end

  	context 'List services after stage' do
    	include_context 'List services after stage', dtk_common
  	end

  	context 'Add component module version to the service' do
  		include_context 'Add versioned component to service', dtk_common, component_module_namespace, component_module_name, component_module_version, service_name, node_name
  	end

  	 context 'Create new assembly from existing service' do
    	include_context 'Create assembly from service', dtk_common, service_module_name, new_assembly, service_module_namespace
  	end

  	context 'Delete and destroy service function' do
    	include_context 'Delete services', dtk_common
  	end

  	context 'Check module_refs.yaml file of service module for versioned component module' do
  		include_context 'Check module_refs.yaml for imported module', service_module_filesystem_location + '/' + service_module_name, ["version: #{component_module_version}"]
  	end

  	context 'Delete assembly function' do
   		include_context 'Delete assembly', dtk_common_new, "#{service_module_name}/#{new_assembly}", service_module_namespace
  	end

  after(:all) do
   	puts '', ''
  end
end
