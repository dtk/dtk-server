#!/usr/bin/env ruby
# Test Case 14: NEG - Create version of a service module that already exists

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

service_module_name = 'temp_service'
service_module_namespace = 'version'
full_service_module_name = 'version:temp_service'
service_module_filesystem_location = '~/dtk/service_modules/version'
version_name = '1.0.0'

dtk_common = Common.new('', '')

describe '(Component, service and versioning) NEG - Test Case 14: Create version of a service module that already exists' do
  
  before(:all) do
    puts '********************************************************************************************************', ''
  end

  context 'Create service module version' do
    include_context 'Create service module version', dtk_common, full_service_module_name, version_name
  end

  context 'Create same service module version' do
    include_context 'NEG - Create service module version', dtk_common, full_service_module_name, version_name
  end

  context "Delete service module version" do
    include_context 'Delete service module version', dtk_common, full_service_module_name, version_name
  end

  after(:all) do
    puts '', ''
  end
end