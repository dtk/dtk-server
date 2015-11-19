#!/usr/bin/env ruby
# Test Case 13: Install service module version, create new version, push it to remote

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/service_modules_spec'
require './lib/service_module_versions_spec'

service_module_name = 'temp_service'
service_module_namespace = 'version'
service_module_fullname = "#{service_module_namespace}:#{service_module_name}"
service_module_remote_name = "#{service_module_namespace}/#{service_module_name}"
service_module_version = '0.0.2'
service_module_filesystem_location = "~/dtk/service_modules/#{service_module_namespace}"

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 13: Install service module version, list assemblies' do
	before(:all) do
		puts '********************************************************************************************************************************************************', ''
	end

	context "Install service module from remote" do
		include_context 'Import remote service module', service_module_remote_name 
	end

	context "Create new service module version" do
		include_context 'Create service module version', dtk_common, service_module_fullname, service_module_version
	end

	context "Check if the created version is on server" do
		include_context 'Check if service module version exists on server', dtk_common, service_module_fullname, service_module_version
	end

	context "Clone created version to local filesystem" do
		include_context 'Clone service module version', dtk_common, service_module_fullname, service_module_version
	end

	context "Check if created service module version exists locally" do
		include_context 'Check if service module verison is exists locally', service_module_filesystem_location, service_module_name, service_module_version
	end
	context "Publish newly creatred service module to remote repo" do
		include_context 'Publish versioned service module', dtk_common, service_module_fullname, service_module_version
	end

	context "Check if published service module version exists on remote repo" do
		include_context 'Check if service module version exists on remote', dtk_common, service_module_fullname, service_module_version
	end

	context "Delete published service module from remote repo" do
		include_context 'Delete remote service module version', dtk_common, service_module_name, service_module_namespace, service_module_version
	end

	context "Check if service module version was deleted from remote" do
		include_context 'NEG - Check if service module version exists on remote', dtk_common, service_module_fullname, service_module_version
	end

	context "Delete service module version that was created" do
		include_context 'Delete service module version', dtk_common, service_module_fullname, service_module_version
	end

	context "Check if service module version was deleted from server" do
		include_context 'NEG - Check if service module version exists on server', dtk_common, service_module_fullname, service_module_version
	end

	context "Delete all installed service module local files" do
		include_context 'Delete all service module versions', dtk_common, service_module_fullname
	end

	context "Delete local service module files" do
		include_context 'Delete all local service module versions', service_module_filesystem_location, service_module_name
	end

	after(:all) do
    	puts '', ''
  	end
end