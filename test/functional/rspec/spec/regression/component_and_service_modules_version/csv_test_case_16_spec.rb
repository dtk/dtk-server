#!/usr/bin/env ruby
# Test Case 16: Install two component modules, add second cmp module version as dependency for first cmp module, delete both and install first cmp module

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'

first_component_module_name = 'temp16_1'
first_full_component_module_name = 'version:temp16_1'
second_component_module_name = 'temp16_2'
second_full_component_module_name = 'version:temp16_2'
component_module_namespace = 'version'
component_module_filesystem_location = '~/dtk/component_modules/version'
version = '0.0.1'
file_for_change = 'module_refs.yaml'
file_for_add = 'module_refs.yaml'
file_for_remove = 'module_refs.yaml'
file_for_change_location = 'spec/regression/component_and_service_modules_version/resources/csv_test_case_16_module_refs.yaml'
dtk_model_yaml_file_location = '~/dtk/component_modules/version/temp16_1/dtk.model.yaml'

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 16: Install two component modules, add second cmp module version as dependency for first cmp module, delete both and install first cmp module' do
	before(:all) do
		puts '*******************************************************************************************************************************************************************************************', ''
	end

	context 'Install first component module' do
    include_context 'Import remote component module', component_module_namespace + '/' + first_component_module_name
  end

  context 'Get first component module components list' do
    include_context 'Get component module components list', dtk_common, first_full_component_module_name
  end

  context 'Check if first component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', component_module_filesystem_location, first_component_module_name
  end

  context 'Install second component module version' do
    include_context 'Install component module version', second_component_module_name, component_module_namespace, version
  end

  context 'Check if second component module version imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', component_module_filesystem_location, second_component_module_name + "-" + version
  end

  context 'Add second cmp module version as dependency for first component module' do
  	include_context 'Add module_refs.yaml file', first_component_module_name, file_for_change_location, file_for_add, component_module_filesystem_location
  end

  context 'Add second cmp module version as dependency for first component module' do
  	include_context 'Add includes to dtk.model.yaml', dtk_model_yaml_file_location, [second_component_module_name]
  end

  context 'Push clone changes to server' do
  	include_context 'Push clone changes to server', first_full_component_module_name, file_for_change
  end

  context 'Publish component module' do
    include_context 'Export component module', first_full_component_module_name, component_module_namespace
  end

  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, first_full_component_module_name
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', component_module_filesystem_location, first_component_module_name
  end

  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, second_full_component_module_name
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', component_module_filesystem_location, second_component_module_name
  end

  context 'Install first component module' do
    include_context 'Import remote component module', component_module_namespace + '/' + first_component_module_name
  end

  context 'Get first component module components list' do
    include_context 'Get component module components list', dtk_common, first_full_component_module_name
  end

  context "Check if the second component module version exists on server" do
    include_context "Check if component module version exists on server", dtk_common, second_full_component_module_name, version
  end

  context 'Revert changes on first component module' do
  	include_context 'Remove includes from dtk.model.yaml', dtk_model_yaml_file_location, [second_component_module_name]
  end

  context 'Revert changes on first component module' do
  	include_context 'Remove module_refs.yaml file', first_component_module_name, file_for_remove, component_module_filesystem_location
  end

	context 'Push clone changes to server' do
  	include_context 'Push clone changes to server', first_full_component_module_name, file_for_change
  end

  context 'Publish component module' do
    include_context 'Export component module', first_full_component_module_name, component_module_namespace
  end 
  
  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, first_full_component_module_name
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', component_module_filesystem_location, first_component_module_name
  end

  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, second_full_component_module_name
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', component_module_filesystem_location, second_component_module_name
  end 

	after(:all) do
    puts '', ''
  end
end