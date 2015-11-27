#!/usr/bin/env ruby
# Test Case 14: Import component module from r8 repo and export to default tenant namespace

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

namespace = 'dtk17'
component_module_name = 'apache'
component_module_namespace = 'r8'
imported_component_module_name = 'r8:apache'
component_module_filesystem_location = '~/dtk/component_modules/r8'
version = '0.0.1'

dtk_common = Common.new('', '')

describe '(Modules, Services and Versioning) Test Case 14: Import component module from r8 repo and export to default tenant namespace' do
  before(:all) do
    puts '****************************************************************************************************************************', ''
  end

  context 'Import component module function' do
    include_context 'Import remote component module', component_module_namespace + '/' + component_module_name
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, imported_component_module_name
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', component_module_filesystem_location, component_module_name
  end

  context "Create new component module version" do
    include_context "Create component module version", dtk_common, imported_component_module_name, version
  end

  context "Publish new component module version to remote repo" do
    include_context "Publish versioned component module", dtk_common, imported_component_module_name, "#{namespace}/#{component_module_name}", version
  end

  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, imported_component_module_name
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', component_module_filesystem_location, component_module_name
  end

  context "Delete new component module from remote repo" do
    include_context "Delete remote component module version", dtk_common, component_module_name, namespace, version
  end

  context 'Delete component module from remote' do
    include_context 'Delete component module from remote repo', component_module_name, namespace
  end

  after(:all) do
    puts '', ''
  end
end
