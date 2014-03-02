#!/usr/bin/env ruby
#Test Case 12: Export service module using full name #{service_module_name} to users default namespace and then delete it

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/service_modules_spec'
require './lib/component_modules_spec'

namespace = "dtk17"
existing_service_module_name = "test_service"
service_module_name = "bakir_test1"
component_module_filesystem_location = '~/dtk/component_modules'
service_filesystem_location = '~/dtk/service_modules'
component_module_namespace = "dtk17"
component_module_name = "test"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 12: Export service module using full name #{service_module_name} to users default namespace and then delete it" do

  before(:all) do
    puts "***********************************************************************************************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 12: Export service module using full name #{service_module_name} to users default namespace and then delete it"
    puts "***********************************************************************************************************************************************************"
    puts ""
  end

  context "Import component module function" do
    include_context "Import remote component module", component_module_namespace + "/" + component_module_name
  end

  context "Import service module function" do
    include_context "Import remote service module", dtk_common, namespace + "/" + existing_service_module_name
  end

  context "List all service modules" do
    include_context "List all service modules", dtk_common, existing_service_module_name
  end

  context "Create new #{service_module_name} directory" do
    it "creates directory #{service_module_name} on local filesystem" do
      puts "Create new #{service_module_name} directory:", "-------------------------------------"
      pass = false
      value = `mkdir #{service_filesystem_location}/#{service_module_name}`
      pass = !value.include?("cannot create directory")
      puts "#{service_module_name} directory was created on local filesystem successfully!" if pass == true
      puts "#{service_module_name} directory was not created on local filesystem successfully!" if pass == false
      puts ""
      pass.should eq(true)
    end
  end

  context "Copy content of #{existing_service_module_name} to new #{service_module_name} service module" do
    it "copies content of #{existing_service_module_name} to new #{service_module_name} service module" do
      puts "Copy content of #{existing_service_module_name} to new #{service_module_name} service module:", "-------------------------------------------------------------------------------"
      pass = false
      value = `cp -r #{service_filesystem_location}/#{existing_service_module_name}/* #{service_filesystem_location}/#{service_module_name}/`
      #not good validation, improve it...
      pass = !value.include?("some error")
      puts "Content of #{existing_service_module_name} copied to #{service_module_name} service successfully!" if pass == true
      puts "Content of #{existing_service_module_name} was not copied to #{service_module_name} service successfully!" if pass == false
      puts ""
      pass.should eq(true)
    end
  end

  context "Import new service module function" do
    include_context "Import service module", service_module_name
  end

  context "Export service module to default namespace" do
    include_context "Export service module", dtk_common, service_module_name, namespace
  end

  context "List all service modules on remote" do
    include_context "List all service modules on remote", dtk_common, service_module_name, namespace
  end

  context "Delete #{service_module_name} service module" do
    include_context "Delete service module", dtk_common, service_module_name
  end

  context "Delete #{service_module_name} service module from remote" do
    include_context "Delete service module from remote repo", dtk_common, service_module_name, namespace
  end

  context "Delete #{service_module_name} service module from local filesystem" do
    include_context "Delete service module from local filesystem", service_filesystem_location, service_module_name
  end

  context "Delete #{existing_service_module_name} service module" do
    include_context "Delete service module", dtk_common, existing_service_module_name
  end

  context "Delete #{existing_service_module_name} service module from local filesystem" do
    include_context "Delete service module from local filesystem", service_filesystem_location, existing_service_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end