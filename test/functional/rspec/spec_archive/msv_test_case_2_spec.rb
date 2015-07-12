#!/usr/bin/env ruby
# Test Case 2: Import component module from remote, version it and use this version-ed component in assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

assembly_name = 'msv_test_case_2_instance'
assembly_template = 'bootstrap::node_with_params'
os = 'precise'
os_attribute = 'os_identifier'
node_name = 'node1'
module_name = 'test'
module_version = '0.0.1'
module_namespace = 'dtk17'
module_filesystem_location = '~/dtk/component_modules'
$assembly_id = 0

dtk_common = Common.new(assembly_name, assembly_template)

describe '(Modules, Services and Versioning) Test Case 2: Import component module from remote, version it and use this version-ed component in assembly' do
  before(:all) do
    puts '*********************************************************************************************************************************************'
    puts '(Modules, Services and Versioning) Test Case 2: Import component module from remote, version it and use this version-ed component in assembly'
    puts '*********************************************************************************************************************************************'
    puts ''
  end

  context 'Import module function' do
    include_context 'Import remote module', module_namespace + '/' + module_name
  end

  context 'Get module components list' do
    include_context 'Get module components list', dtk_common, module_name
  end

  context 'Check if module imported on local filesystem' do
    include_context 'Check module imported on local filesystem', module_filesystem_location, module_name
  end

  context "Create new version of module #{module_name}" do
    include_context 'Create new module version', dtk_common, module_name, module_version
  end

  context 'Get versioned module components list' do
    include_context 'Get versioned module components list', dtk_common, module_name, module_version
  end

  context "Stage assembly function on #{assembly_template} assembly template" do
    include_context 'Stage', dtk_common
  end

  context 'List assemblies after stage' do
    include_context 'List assemblies after stage', dtk_common
  end

  context 'Set os attribute function' do
    include_context 'Set attribute', dtk_common, os_attribute, os
  end

  context 'Add versioned components to assembly node' do
    include_context 'Add component to assembly node', dtk_common, node_name, "#{module_name}(#{module_version})"
  end

  context 'Converge function' do
    include_context 'Converge', dtk_common
  end

  context 'Delete and destroy assembly function' do
    include_context 'Delete assemblies', dtk_common
  end

  context 'Delete module' do
    include_context 'Delete module', dtk_common, module_name
  end

  context 'Delete module from local filesystem' do
    include_context 'Delete module from local filesystem', module_filesystem_location, module_name
  end

  after(:all) do
    puts '', ''
  end
end
