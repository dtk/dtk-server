#!/usr/bin/env ruby
# Test Case 02: Install component module version, create new version, push it to remote

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'

component_module_name = 'temp02'
component_module_namespace = 'version'
component_module_remote_name = "#{component_module_namespace}/#{component_module_name}"
component_module_fullname = "#{component_module_namespace}:#{component_module_name}"
component_module_existing_version = '0.0.1'
component_module_new_version = '0.0.2'
component_module_filesystem_location = "~/dtk/component_modules/#{component_module_namespace}"

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 02: Install component module version, create new version, push it to remote' do
	before(:all) do
    	puts '*********************************************************************************************************************************', ''
  	end

	context "Install component module version from remote" do
		include_context "Install component module version", component_module_name, component_module_namespace, component_module_existing_version
	end

	context "Check if the component module version exists on server" do
		include_context "Check if component module version exists on server", dtk_common, component_module_fullname, component_module_existing_version
	end

	context "Create new component module version" do
		include_context "Create component module version", dtk_common, component_module_fullname, component_module_new_version
	end

	context "Check if the created component module version exists on server" do
		include_context "Check if component module version exists on server", dtk_common, component_module_fullname, component_module_new_version
	end

	context "Publish new component module version to remote repo" do
		include_context	"Publish versioned component module", dtk_common, component_module_fullname, component_module_new_version
	end

	context "Check if the component module was published to the remote repo" do
		include_context "Check if component module version exists on remote", dtk_common, component_module_fullname, component_module_new_version
	end

	context "Delete new component module from remote repo" do
		include_context "Delete remote component module version", dtk_common, component_module_name, component_module_namespace, component_module_new_version
	end

	context "Delete all component module versions from server" do
		include_context "Delete all component module versions", dtk_common, component_module_fullname
	end

	context "Delete all component module versions from local filesystem" do
		include_context 'Delete all local component module versions', component_module_filesystem_location, component_module_name
	end

	after(:all) do
    	puts '', ''
  	end
end