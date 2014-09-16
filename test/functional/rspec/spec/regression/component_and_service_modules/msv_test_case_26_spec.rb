#!/usr/bin/env ruby
# Test Case 26: NEG - Import new service module but its referenced component module exists locally but not on server

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'
require './lib/component_modules_spec'

service_module_name = 'bakir_test_apache'
service_module_namespace = 'r8'
local_service_module_name = 'r8:bakir_test_apache'
component_module_namespace = 'r8'
component_module_name = 'apache'
local_component_module_name = 'r8:apache'
service_module_filesystem_location = '~/dtk/service_modules/r8'
component_module_filesystem_location = '~/dtk/component_modules/r8'

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 26: NEG - Import new service module but its referenced component module exists locally but not on server" do

  before(:all) do
    puts "*****************************************************************************************************************************************************",""
  end

  context "Import component module function" do
    include_context "Import remote component module", component_module_namespace + "/" + component_module_name
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, component_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, local_component_module_name
  end

  context "Import service module function when referenced component module exists only on local filesystem" do
    include_context "NEG - Import remote service module", dtk_common, service_module_namespace + "/" + service_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end