#!/usr/bin/env ruby
# Test Case 03 (N): Create version of a component module that already exists, is invalid format, or is left out

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'

component_module_name = 'dummy'
component_module_namespace = 'version'
component_module_remote_name = "#{component_module_namespace}/#{component_module_name}"
component_module_fullname = "#{component_module_namespace}:#{component_module_name}"
component_module_existing_version = '0.0.1'
component_module_version_invalid_format = 'value'
component_module_verion_left_out = ' '
component_module_filesystem_location = "~/dtk/component_modules/#{component_module_namespace}"

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 03 (N): Create version of a component module that already exists, is invalid format, or is left out' do
	before(:all) do
    	puts '*********************************************************************************************************************************', ''
  	end

	context "Check if versioned component module exists on server" do
		include_context 'Check if component module exists', dtk_common, component_module_fullname
	end

	context "Create component module version that already exists" do
		include_context 'NEG - Create component module version', dtk_common, component_module_fullname, component_module_existing_version
	end

	context "Create component module version that already exists" do
		include_context 'NEG - Create component module version', dtk_common, component_module_fullname, component_module_version_invalid_format
	end

	context "Create component module version that already exists" do
		include_context 'NEG - Create component module version', dtk_common, component_module_fullname, component_module_verion_left_out
	end

	after(:all) do
    	puts '', ''
  	end
end