#!/usr/bin/env ruby
# Test Case 49: Import puppet forge (erlang) with specifying namespace and check its dependencies are installed correctly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

puppet_forge_module_name = "garethr-erlang"
module_name = "erlang"
namespace = "test"
component_module_name = "test:erlang"
dependency_module_name = "epel"
dependency_component_module_name = "stahnma:epel"
component_module_filesystem_location = '~/dtk/component_modules/test'
dependency_component_module_filesystem_location = '~/dtk/component_modules/stahnma'
grep_patterns_for_module_refs = ['epel:','namespace: stahnma']
dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 49: Import puppet forge (erlang) with specifying namespace and check its dependencies are installed correctly" do

  before(:all) do
    puts "*********************************************************************************************************************************************************",""
  end

  context "Import module from puppet forge" do
    include_context "Import module from puppet forge", puppet_forge_module_name, namespace
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, component_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, dependency_component_module_name
  end

  context "Check module_refs.yaml for imported module" do
    include_context "Check module_refs.yaml for imported module", component_module_filesystem_location + "/" + module_name, grep_patterns_for_module_refs
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, dependency_component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", dependency_component_module_filesystem_location, dependency_module_name
  end
  
  after(:all) do
    puts "", ""
  end
end