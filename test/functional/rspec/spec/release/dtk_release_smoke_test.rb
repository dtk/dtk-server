#!/usr/bin/env ruby
# This is DTK Server smoke test used for execution in DTK Release process

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'
require './lib/service_modules_spec'

catalog_username = "dtk16"
catalog_password = "password"
service_name = 'dtk_release_smoke_test'
assembly_name = 'bootstrap::node_with_params'
os_templates = ['precise','rhel6']
os_attribute = 'os_identifier'
memory_size = 't1.micro'
memory_size_attribute = 'memory_size'
node_name = 'node1'
component_module_name = "test_module"
local_component_module_name = 'local:test_module'
service_module_name = "bootstrap"
local_service_module_name = 'local:bootstrap'
namespace = 'dtk16'
local_default_namespace = 'local'
component_module_filesystem_location = "~/dtk/component_modules"
rvm_path = "/usr/local/rvm/wrappers/default"

dtk_common = DtkCommon.new(service_name, assembly_name)

describe "DTK Server smoke test release" do

  before(:all) do
    puts "*****************************",""
  end

  context "Set catalog credentials" do
    include_context "Set catalog credentials", dtk_common, catalog_username, catalog_password
  end

  context "Set default namespace" do
    include_context "Set default namespace", dtk_common, local_default_namespace
  end

  context "Import new component module function" do
    include_context "Import component module", rvm_path, component_module_name
  end

  context "Import new service module function" do
    include_context "Import service module", rvm_path, service_module_name
  end

  context "Export component module to #{namespace} namespace" do
    include_context "Export component module", rvm_path, dtk_common, local_component_module_name, namespace
  end

  context "Export service module to #{namespace} namespace" do
    include_context "Export service module", rvm_path, dtk_common, local_service_module_name, namespace
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, local_component_module_name
  end

  os_templates.each do |os|
    context "Stage service function on #{assembly_name} assembly" do
      include_context "Stage", dtk_common
    end

    context "List services after stage" do    
      include_context "List services after stage", dtk_common
    end

    context "Set os attribute function" do
      include_context "Set attribute", dtk_common, os_attribute, os
    end

    context "Set memory size attribute function" do
      include_context "Set attribute", dtk_common, memory_size_attribute, memory_size
    end

    context "Converge function" do
      include_context "Converge service", dtk_common, 30
    end

    context "Delete and destroy service function" do
      include_context "Delete services", dtk_common
    end
  end

  context "Delete service module function" do
    include_context "Delete service module", dtk_common, local_service_module_name
  end

  context "Delete component module function" do
    include_context "Delete component module", dtk_common, local_component_module_name
  end

  context "Delete #{local_component_module_name} component module from remote" do
    include_context "Delete component module from remote repo", rvm_path, dtk_common, local_component_module_name, namespace
  end

  context "Delete #{local_service_module_name} service module from remote" do
    include_context "Delete service module from remote repo", rvm_path, dtk_common, local_service_module_name, namespace
  end

  after(:all) do
    puts "", ""
  end
end
