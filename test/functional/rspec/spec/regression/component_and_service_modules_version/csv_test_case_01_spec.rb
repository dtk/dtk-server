#!/usr/bin/env ruby
# Test Case 01: Create component module version, publish it and check remote for version

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'

component_module_name = 'temp01'
component_module_namespace = 'version'
component_module_fullname = "#{component_module_namespace}:#{component_module_name}"
component_module_version = '0.0.1'
component_module_source = "./modules/#{component_module_name}"
component_module_filesystem_location = "~/dtk/component_modules/#{component_module_namespace}"

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 01: Create component module version, publish it and check remote for version' do
	before(:all) do
    	puts '**********************************************************************************************************************', ''
  	end
  	
  	context "Check if component module base version exists" do
  		include_context 'Check if component module exists', dtk_common, component_module_fullname
  	end

	context 'Create new component module version' do
		include_context 'Create component module version', dtk_common, component_module_fullname, component_module_version
	end

	context 'Check if the created version exists on server' do
		include_context 'Check if component module version exists on server', dtk_common, component_module_fullname, component_module_version
	end
	
	context "Publish new component module version to remote repo" do
    include_context "Publish versioned component module", dtk_common, component_module_fullname, "#{component_module_namespace}/#{component_module_name}", component_module_version
  end

	context 'Check if the component module was published successfully' do
		include_context 'Check if component module version exists on remote', dtk_common, component_module_fullname, component_module_version
	end

	context 'Delete component module version from remote' do
		include_context 'Delete remote component module version', dtk_common, component_module_name, component_module_namespace, component_module_version
	end

	context 'Delete base component module version from remote' do
		include_context 'Delete component module from remote repo', component_module_name, component_module_namespace
	end

	context 'Check if the component module version was deleted from remote' do
		include_context 'NEG - Check if component module version exists on remote', dtk_common, component_module_fullname, component_module_version
	end

	context 'Delete component module version from server' do
		include_context 'Delete component module version', dtk_common, component_module_fullname, component_module_version
	end

	context 'Check if the component module version was deleted successfully' do
		include_context 'NEG - Check if component module version exists on server', dtk_common, component_module_fullname, component_module_version
	end

	context 'Delete component module version from local filesystem' do
		include_context 'Delete versioned component module from local filesystem', component_module_filesystem_location, component_module_name, component_module_version
	end

	after(:all) do
    	puts '', ''
  	end
end