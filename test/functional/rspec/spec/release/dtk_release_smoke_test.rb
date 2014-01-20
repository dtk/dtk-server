#!/usr/bin/env ruby
#This is DTK Server smoke test used for execution in DTK Release process

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'
require './lib/services_spec'

assembly_name = 'dtk_release_smoke_test'
assembly_template = 'bootstrap::node_with_params'
os_templates = ['precise','centos6.4']
os_attribute = 'os_identifier'
memory_size = 't1.micro'
memory_size_attribute = 'memory_size'
node_name = 'node1'
module_name = "test"
service_name = "bootstrap"
module_filesystem_location = "~/dtk/component_modules"
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "DTK Server smoke test release" do

  before(:all) do
    puts "*****************************"
    puts "DTK Server smoke test release"
    puts "*****************************"
    puts ""
  end

  context "Create new module function" do
    include_context "Create module", module_name
  end

  context "Create new service function" do
    include_context "Import service", service_name
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, module_name
  end

  os_templates.each do |os|
    context "Stage assembly function on #{assembly_template} assembly template" do
      include_context "Stage", dtk_common
    end

    context "List assemblies after stage" do    
      include_context "List assemblies after stage", dtk_common
    end

    context "Set os attribute function" do
      include_context "Set attribute", dtk_common, os_attribute, os
    end

    context "Set memory size attribute function" do
      include_context "Set attribute", dtk_common, memory_size_attribute, memory_size
    end

    context "Converge function" do
      include_context "Converge assembly", dtk_common, 30
    end

    context "Delete and destroy assembly function" do
      include_context "Delete assemblies", dtk_common
    end
  end

  context "Delete service" do
    include_context "Delete service", dtk_common, service_name
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name
  end

  after(:all) do
    puts "", ""
  end
end
