#!/usr/bin/env ruby
# Test Case 10: Publish component module using full name #{component_module_name} to users default namespace and then delete it

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

existing_component_module_name = 'jmeter'
component_module_namespace = 'r8'
existing_component_module = 'r8:jmeter'
namespace = 'dtk17'
component_module_name = 'bakir_test1'
local_component_module = 'local:bakir_test1'
new_local_component_module = 'dtk17:bakir_test1'
default_filesystem_location = '~/dtk/component_modules'
r8_component_module_filesystem_location = '~/dtk/component_modules/r8'
dtk17_component_module_filesystem_location = '~/dtk/component_modules/dtk17'
local_component_module_filesystem_location = '~/dtk/component_modules/local'
version = "0.0.1"

dtk_common = Common.new('', '')

describe "(Modules, Services and Versioning) Test Case 10: Publish component module using full name #{component_module_name} to users default namespace and then delete it" do
  before(:all) do
    puts '***************************************************************************************************************************************************************', ''
  end

  context 'Import component module function' do
    include_context 'Import remote component module', component_module_namespace + '/' + existing_component_module_name
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, existing_component_module
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', r8_component_module_filesystem_location, existing_component_module_name
  end

  context "Create new directory called #{component_module_name} and copy the content of #{existing_component_module} in it" do
    it 'creates new directory with existing component module content in it' do
      puts 'Create new directory and copy the content of existing component module', '----------------------------------------------------------------------'
      pass = false
      `mkdir -p #{default_filesystem_location}/#{component_module_name}`
      `cp -r #{r8_component_module_filesystem_location}/#{existing_component_module_name}/* #{default_filesystem_location}/#{component_module_name}/`
      value = `ls #{default_filesystem_location}/#{component_module_name}/manifests`
      pass = !value.include?('No such file or directory')
      puts ''
      pass.should eq(true)
    end
  end

  context 'Import new component module function' do
    include_context 'Import component module', component_module_name
  end

  context "Create new component module version" do
    include_context "Create component module version", dtk_common, local_component_module, version
  end

  context "Publish new component module version to remote repo" do
    include_context "Publish versioned component module", dtk_common, local_component_module, "#{namespace}/#{component_module_name}", version
  end

  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, local_component_module
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', local_component_module_filesystem_location, component_module_name
  end

  context 'Delete old component module' do
    include_context 'Delete component module', dtk_common, existing_component_module
  end

  context 'Delete old component module from local filesystem' do
    include_context 'Delete component module from local filesystem', r8_component_module_filesystem_location, existing_component_module_name
  end

  context 'Import component module function' do
    include_context 'Import remote component module', "#{namespace}/#{component_module_name}"
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', dtk17_component_module_filesystem_location, component_module_name
  end

  context 'Check if component module version imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', dtk17_component_module_filesystem_location, component_module_name + "-" + version
  end

  context "Delete all component module versions from server" do
    include_context "Delete all component module versions", dtk_common, new_local_component_module
  end

  context "Delete all component module versions from local filesystem" do
    include_context 'Delete all local component module versions', dtk17_component_module_filesystem_location, component_module_name
  end

  context "Delete new component module from remote repo" do
    include_context "Delete remote component module version", dtk_common, component_module_name, namespace, version
  end

  context 'Delete remote module' do
    include_context 'Delete component module from remote', dtk_common, component_module_name, namespace
  end
  
  after(:all) do
    puts '', ''
  end
end
