#!/usr/bin/env ruby
#Test Case 26: NEG - Import new service but its referenced module exists locally but not on server

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/services_spec'
require './lib/modules_spec'

service_name = 'bakir_test_apache'
service_namespace = 'r8'
module_namespace = 'r8'
module_name = 'apache'
service_filesystem_location = '~/dtk/service_modules'
module_filesystem_location = '~/dtk/component_modules'
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 26: NEG - Import new service but its referenced module exists locally but not on server" do

  before(:all) do
    puts "************************************************************************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 26: NEG - Import new service but its referenced module exists locally but not on server"
    puts "************************************************************************************************************************************"
    puts ""
  end

  context "Import module function" do
    include_context "Import remote module", module_namespace + "/" + module_name
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Import service function when referenced module exists only on local filesystem" do
    include_context "NEG - Import remote service", dtk_common, service_namespace + "/" + service_name
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end

  after(:all) do
    puts "", ""
  end
end