#!/usr/bin/env ruby
#Test Case 74: Import service from remote repo and check its corresponding assembly templates

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/services_spec'

assembly_template1 = 'redhat_bigtop_namenode'
assembly_template2 = 'redhat_hdp_namenode'
service_name = 'bakir_test_service'
service_namespace = 'r8'
service_filesystem_location = '~/dtk/service_modules'
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "Test Case 74: Import service from remote repo and check its corresponding assembly templates" do

  before(:all) do
    puts "********************************************************************************************"
    puts "Test Case 74: Import service from remote repo and check its corresponding assembly templates"
    puts "********************************************************************************************"
    puts ""
  end

  context "Import service function" do
    include_context "Import remote service", dtk_common, service_namespace + "/" + service_name
  end

  context "List all services" do
    include_context "List all services", dtk_common, service_name
  end

  context "Check if #{assembly_template1} assembly_template belongs to #{service_name} service" do
    include_context "Check if assembly template belongs to the service", dtk_common, service_name, assembly_template1
  end

  context "Check if #{assembly_template2} assembly_template belongs to #{service_name} service" do
    include_context "Check if assembly template belongs to the service", dtk_common, service_name, assembly_template2
  end

  context "Delete service function" do
    include_context "Delete service", dtk_common, service_name
  end

  context "Delete service from local filesystem" do
    include_context "Delete service from local filesystem", service_filesystem_location, service_name
  end

  after(:all) do
    puts "", ""
  end
end