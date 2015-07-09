#!/usr/bin/env ruby
# Test Case 20: Import service module from remote repo and check its corresponding assemblies

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/service_modules_spec'
require './lib/component_modules_spec'

assembly_name = 'test_apache'
service_module_name = 'bakir_test_apache'
service_module_namespace = 'r8'
local_service_module_name = 'r8:bakir_test_apache'
service_module_filesystem_location = '~/dtk/service_modules/r8'
component_module_filesystem_location = '~/dtk/component_modules/r8'
component_module_name = 'apache'
local_component_module_name = 'r8:apache'

dtk_common = DtkCommon.new('', '')

describe '(Modules, Services and Versioning) Test Case 20: Import service module from remote repo and check its corresponding assemblies' do
  before(:all) do
    puts '******************************************************************************************************************************',''
  end

  context 'Import service module function' do
    include_context 'Import remote service module', service_module_namespace + '/' + service_module_name
  end

  context 'List all service modules' do
    include_context 'List all service modules', dtk_common, local_service_module_name
  end

  context "Check if #{assembly_name} assembly belongs to #{local_service_module_name} service module" do
    include_context 'Check if assembly belongs to the service module', dtk_common, local_service_module_name, assembly_name
  end

  context 'Delete service module function' do
    include_context 'Delete service module', dtk_common, local_service_module_name
  end

  context 'Delete service module from local filesystem' do
    include_context 'Delete service module from local filesystem', service_module_filesystem_location, service_module_name
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, local_component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts '', ''
  end
end
