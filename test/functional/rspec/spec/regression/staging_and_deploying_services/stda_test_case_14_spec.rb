#!/usr/bin/env ruby
# Test Case 14: Using lambda function in dtk.model.yaml

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/service_modules_spec'
require './lib/component_modules_spec'

STDOUT.sync = true

namespace = "dtk17"
service_module_name = "service_with_lambda"
imported_service_module_name = "dtk17:service_with_lambda"
component_module_name = "module_with_lambda"
imported_component_module_name = "dtk17:module_with_lambda"
component_module_filesystem_location = '~/dtk/component_modules/dtk17'
service_module_filesystem_location = '~/dtk/service_modules/dtk17'

service_name = 'stda_test_case_14_instance'
assembly_name = 'service_with_lambda::lambda'
dtk_common = Common.new(service_name, assembly_name)

expected_output_1 = {
	:command => "cat /tmp/test | grep 55",
	:status => 0,
	:stderr => nil,
}

describe "(Staging And Deploying Assemblies) Test Case 14: Using lambda function in dtk.model.yaml" do

	before(:all) do
		puts "**************************************************************************************",""
  end

  context "Import service module function" do
    include_context "Import remote service module", namespace + "/" + service_module_name
  end

  context "List all service modules" do
    include_context "List all service modules", dtk_common, imported_service_module_name
  end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage", dtk_common
	end

	context "List services after stage" do		
		include_context "List services after stage", dtk_common
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Get task action details for action with bash script command" do
		include_context "Get task action details", dtk_common, "4.1", [expected_output_1]
	end

	context "Delete and destroy service function" do
		include_context "Delete services", dtk_common
	end

	context "List services after delete" do
		include_context "List services after delete", dtk_common
	end

	context "Delete #{imported_service_module_name} service module" do
    include_context "Delete service module", dtk_common, imported_service_module_name
  end

  context "Delete #{service_module_name} service module from local filesystem" do
    include_context "Delete service module from local filesystem", service_module_filesystem_location, service_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, imported_component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, component_module_name
  end

	after(:all) do
		puts "", ""
	end
end
