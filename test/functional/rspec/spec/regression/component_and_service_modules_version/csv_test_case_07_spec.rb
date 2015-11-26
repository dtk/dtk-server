#!/usr/bin/env ruby
# Test Case 07: Check if deleting base component module version from remote will delete all versions

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

component_module_name = 'temp07'
component_module_namespace = 'version'
imported_component_module_name = 'version:temp07'
component_module_filesystem_location = '~/dtk/component_modules/version'
version = '0.0.1'

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 07: Check if deleting base component module version from remote will delete all versions' do
  before(:all) do
    puts '*************************************************************************************************************************************', ''
  end

  context 'Install component module' do
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

  context 'Publish component module' do
    include_context 'Export component module', imported_component_module_name, component_module_namespace
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