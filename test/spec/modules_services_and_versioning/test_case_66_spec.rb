#!/usr/bin/env ruby
#Test Case 66: Export service using full name #{service_name} to users default namespace and then delete it

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/services_spec'

namespace = "dtk17"
service_name = "bakir_test1"
service_filesystem_location = '~/dtk/service_modules'
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "Test Case 66: Export service using full name #{service_name} to users default namespace and then delete it" do

  before(:all) do
    puts "**********************************************************************************************************"
    puts "Test Case 66: Export service using full name #{service_name} to users default namespace and then delete it"
    puts "**********************************************************************************************************"
    puts ""
  end

  context "Create new service function" do
    include_context "Create service", dtk_common, service_name
  end

  context "Export service to default namespace" do
    include_context "Export service", dtk_common, service_name, namespace
  end

  context "List all services on remote" do
    include_context "List all services on remote", dtk_common, service_name, namespace
  end

  context "Delete service" do
    include_context "Delete service", dtk_common, service_name
  end

  context "Delete service from remote" do
    include_context "Delete service from remote repo", dtk_common, service_name, namespace
  end

  context "Delete service from local filesystem" do
    include_context "Delete service from local filesystem", service_filesystem_location, service_name
  end

  after(:all) do
    puts "", ""
  end
end