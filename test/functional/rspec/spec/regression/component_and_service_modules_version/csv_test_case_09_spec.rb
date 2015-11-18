#!/usr/bin/env ruby
# Test Case 09: Import component module from local filesystem, version it, publish version

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'

component_module_name = 'temp09'
component_module_namespace = 'version'
imported_component_module_name = 'version:temp09'
component_module_filesystem_location = '~/dtk/component_modules/version'
version = '0.0.1'
file_name = 'csv_test_case_09_dtk.model.yaml'
file_to_copy_location = './spec/regression/component_and_service_modules_version/resources/csv_test_case_09_dtk.model.yaml'

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 09: Import component module from local filesystem, version it, publish version' do
  before(:all) do
    puts '****************************************************************************************************************************', ''
  end

  context 'Create component module on local filesystem' do
    include_context 'Create component module on local filesystem', component_module_filesystem_location, component_module_name, file_to_copy_location, file_name
  end

  context 'Import component module' do
    include_context 'Import component module', imported_component_module_name
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, imported_component_module_name
  end

  context "Create new component module version" do
    include_context "Create component module version", dtk_common, imported_component_module_name, version
  end

  context "Check if the created component module version exists on server" do
    include_context "Check if component module version exists on server", dtk_common, imported_component_module_name, version
  end

  context "Publish new component module version to remote repo" do
    include_context "Publish versioned component module", dtk_common, imported_component_module_name, version
  end

  context "Check if the component module was published to the remote repo" do
    include_context "Check if component module version exists on remote", dtk_common, imported_component_module_name, version
  end

  context 'Delete base component module from remote' do
    include_context 'Delete component module from remote repo', component_module_name, component_module_namespace
  end

  context 'Check if component module version exists on remote' do
    include_context 'NEG - Check if component module version exists on remote', dtk_common, imported_component_module_name, version
  end

  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, imported_component_module_name
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts '', ''
  end
end