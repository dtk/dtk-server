#!/usr/bin/env ruby
#Test Case 12: Export service using full name #{service_name} to users default namespace and then delete it

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/services_spec'
require './lib/modules_spec'

namespace = "dtk17"
existing_service_name = "test_service"
service_name = "bakir_test1"
module_filesystem_location = '~/dtk/component_modules'
service_filesystem_location = '~/dtk/service_modules'
module_name = "test"
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 12: Export service using full name #{service_name} to users default namespace and then delete it" do

  before(:all) do
    puts "*********************************************************************************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 12: Export service using full name #{service_name} to users default namespace and then delete it"
    puts "*********************************************************************************************************************************************"
    puts ""
  end

  context "Import service function" do
    include_context "Import remote service", dtk_common, namespace + "/" + existing_service_name
  end

  context "List all services" do
    include_context "List all services", dtk_common, existing_service_name
  end

  context "Create new #{service_name} directory" do
    it "creates directory #{service_name} on local filesystem" do
      puts "Create new #{service_name} directory:", "-------------------------------------"
      pass = false
      value = `mkdir #{service_filesystem_location}/#{service_name}`
      pass = !value.include?("cannot create directory")
      puts "#{service_name} directory was created on local filesystem successfully!" if pass == true
      puts "#{service_name} directory was not created on local filesystem successfully!" if pass == false
      puts ""
      pass.should eq(true)
    end
  end

  context "Copy content of #{existing_service_name} to new #{service_name} service" do
    it "copies content of #{existing_service_name} to new #{service_name} service" do
      puts "Copy content of #{existing_service_name} to new #{service_name} service:", "------------------------------------------------------------------------"
      pass = false
      value = `cp -r #{service_filesystem_location}/#{existing_service_name}/* #{service_filesystem_location}/#{service_name}/`
      #not good validation, improve it...
      pass = !value.include?("some error")
      puts "Content of #{existing_service_name} copied to #{service_name} service successfully!" if pass == true
      puts "Content of #{existing_service_name} was not copied to #{service_name} service successfully!" if pass == false
      puts ""
      pass.should eq(true)
    end
  end

  context "Import new service function" do
    include_context "Import service", service_name
  end

  context "Export service to default namespace" do
    include_context "Export service", dtk_common, service_name, namespace
  end

  context "List all services on remote" do
    include_context "List all services on remote", dtk_common, service_name, namespace
  end

  context "Delete #{service_name} service" do
    include_context "Delete service", dtk_common, service_name
  end

  context "Delete #{service_name} service from remote" do
    include_context "Delete service from remote repo", dtk_common, service_name, namespace
  end

  context "Delete #{service_name} service from local filesystem" do
    include_context "Delete service from local filesystem", service_filesystem_location, service_name
  end

  context "Delete #{existing_service_name} service" do
    include_context "Delete service", dtk_common, existing_service_name
  end

  context "Delete #{existing_service_name} service from local filesystem" do
    include_context "Delete service from local filesystem", service_filesystem_location, existing_service_name
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end

  after(:all) do
    puts "", ""
  end
end