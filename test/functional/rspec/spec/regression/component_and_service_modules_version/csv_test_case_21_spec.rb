#!/usr/bin/env ruby
# Test Case 21: Import service module from local filesystem, version it, publish version

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/service_modules_spec'
require './lib/service_module_versions_spec'

service_module_name = 'temp21'
service_module_namespace = 'version'
imported_service_module_name = 'version:temp21'
service_module_filesystem_location = '~/dtk/service_modules/version'
version = '0.0.1'
file_name = 'csv_test_case_21_dtk.assembly.yaml'
file_to_copy_location = './spec/regression/component_and_service_modules_version/resources/csv_test_case_21_dtk.assembly.yaml'
assembly_name = "temp21"

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 21: Import service module from local filesystem, version it, publish version' do
  before(:all) do
    puts '**************************************************************************************************************************', ''
  end

  context 'Create service module on local filesystem' do
    include_context 'Create service module on local filesystem', service_module_filesystem_location, service_module_name, file_to_copy_location, file_name, assembly_name
  end

  context 'Import service module' do
    include_context 'Import service module', imported_service_module_name
  end

  context "Create new service module version" do
    include_context "Create service module version", dtk_common, imported_service_module_name, version
  end

  context "Check if the created service module version exists on server" do
    include_context "Check if service module version exists on server", dtk_common, imported_service_module_name, version
  end

  context "Publish new service module version to remote repo" do
    include_context "Publish versioned service module", dtk_common, imported_service_module_name, version
  end

  context "Check if the service module was published to the remote repo" do
    include_context "Check if service module version exists on remote", dtk_common, imported_service_module_name, version
  end

  context 'Delete base service module from remote' do
    include_context 'Delete service module from remote repo', service_module_name, service_module_namespace
  end

  context 'Check if service module version exists on remote' do
    include_context 'NEG - Check if service module version exists on remote', dtk_common, imported_service_module_name, version
  end

  context "Delete all service module versions from server" do
    include_context "Delete all service module versions", dtk_common, imported_service_module_name
  end

  context "Delete all service module versions from local filesystem" do
    include_context 'Delete all local service module versions', service_module_filesystem_location, service_module_name
  end

  after(:all) do
    puts '', ''
  end
end