#!/usr/bin/env ruby
# Test Case 25: Install service module, add cmp module version as dependency to module_refs.yaml, create new version of service module, publish it, delete modules and install service module version again and check that cmp module version is also installed

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'
require './lib/service_module_versions_spec'
require './lib/service_modules_spec'

service_module_namespace = 'version'
component_module_namespace = 'version'
service_module_name = 'temp_service_25'
component_module_name = 'temp25'
assembly_name = 'test'
full_service_module_name = "#{service_module_namespace}:#{service_module_name}"
full_component_module_name = "#{component_module_namespace}:#{component_module_name}"
service_module_filesystem_location = "~/dtk/service_modules/#{service_module_namespace}"
component_module_filesystem_location = "~/dtk/component_modules/#{component_module_namespace}"
component_module_version = '0.0.1'
service_module_version = '0.0.1'
file_for_change = 'module_refs.yaml'
file_for_add = 'module_refs.yaml'
file_for_remove = 'module_refs.yaml'
file_for_change_location = 'spec/regression/component_and_service_modules_version/resources/csv_test_case_25_first_module_refs.yaml'
file_for_restore_location = 'spec/regression/component_and_service_modules_version/resources/csv_test_case_25_second_module_refs.yaml'
assembly_yaml_file_location = "~/dtk/service_modules/#{service_module_namespace}/#{service_module_name}/assemblies/#{assembly_name}/assembly.yaml"
module_refs_file_location = "~/dtk/service_modules/#{service_module_namespace}/#{service_module_name}/module_refs.yaml"

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 25: Install service module, add cmp module version as dependency to module_refs.yaml, create new version of service module, publish it, delete modules and install service module version again and check that cmp module version is also installed' do
	before(:all) do
		puts '************************************************************************************************************************************************************************************************************', ''
	end

	context 'Install service module' do
    include_context 'Import remote service module', service_module_namespace + '/' + service_module_name
  end

  context 'Check if service module is imported to local filesystem' do
  	include_context 'Check service module imported on local filesystem', service_module_filesystem_location, service_module_name
  end

  context 'Install component module version' do
  	include_context 'Install component module version', component_module_name, component_module_namespace, component_module_version
  end

  context 'Check if component module is imported to local filesystem' do
  	include_context 'Check component module imported on local filesystem', component_module_filesystem_location, component_module_name + '-' + component_module_version
  end

  context 'Add component module as dependency for service module' do
  	include_context 'Add module_refs.yaml file', service_module_name, file_for_change_location, file_for_add, service_module_filesystem_location
  end

  context 'Push service module changes to server' do
  	include_context 'Push local service module changes to server', full_service_module_name, file_for_change
  end

  context 'Create new service module version' do
    include_context 'Create service module version', dtk_common, full_service_module_name, service_module_version
  end
=begin
  context 'Publish service module version to remote repo' do
  	include_context 'Publish versioned service module', dtk_common, full_service_module_name, service_module_version
  end

  context 'Delete all service module version from server' do
  	include_context 'Delete all service module versions', dtk_common, full_service_module_name
  end

  context 'Delete all local service module version files' do
  	include_context 'Delete all local service module versions', service_module_filesystem_location, service_module_name
  end

  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, full_component_module_name
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', component_module_filesystem_location, component_module_name
  end

  context 'Install service module version from remote' do
    include_context 'Install service module version', service_module_name, service_module_namespace, service_module_version
  end

  context "Check if the component module version exists on server" do
    include_context "Check if component module version exists on server", dtk_common, full_component_module_name, component_module_version
  end

  context 'Delete service module version from remote repo' do
  	include_context 'Delete remote service module version', dtk_common, service_module_name, service_module_namespace, service_module_version
  end

  context 'Delete all service module version from server' do
    include_context 'Delete all service module versions', dtk_common, full_service_module_name
  end

  context 'Delete all local service module version files' do
    include_context 'Delete all local service module versions', service_module_filesystem_location, service_module_name
  end

  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, full_component_module_name
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', component_module_filesystem_location, component_module_name
  end
=end
  after(:all) do
    puts '', ''
  end
end