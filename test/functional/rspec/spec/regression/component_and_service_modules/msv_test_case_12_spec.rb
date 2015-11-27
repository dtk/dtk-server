#!/usr/bin/env ruby
# Test Case 12: Export service module using full name #{service_module_name} to users default namespace and then delete it

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/service_modules_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'
require './lib/service_module_versions_spec'

namespace = 'dtk17'
existing_service_module_name = 'test_service'
imported_service_module_name = 'dtk17:test_service'
service_module_name = 'bakir_test1'
local_service_module_name = 'local:bakir_test1'
component_module_filesystem_location = '~/dtk/component_modules/dtk17'
service_filesystem_location = '~/dtk/service_modules/dtk17'
default_service_filesystem_location = '~/dtk/service_modules'
local_service_filesystem_location = '~/dtk/service_modules/local'
version = '0.0.1'

dtk_common = Common.new('', '')

describe "(Modules, Services and Versioning) Test Case 12: Export service module using full name #{service_module_name} to users default namespace and then delete it" do
  before(:all) do
    puts '***********************************************************************************************************************************************************', ''
  end

  context 'Import service module function' do
    include_context 'Import remote service module', namespace + '/' + existing_service_module_name
  end

  context 'List all service modules' do
    include_context 'List all service modules', dtk_common, imported_service_module_name
  end

  context "Create new #{service_module_name} directory" do
    it "creates directory #{service_module_name} on local filesystem" do
      puts "Create new #{service_module_name} directory:", '-------------------------------------'
      pass = false
      value = `mkdir -p #{default_service_filesystem_location}/#{service_module_name}`
      pass = !value.include?('cannot create directory')
      puts "#{service_module_name} directory was created on local filesystem successfully!" if pass == true
      puts "#{service_module_name} directory was not created on local filesystem successfully!" if pass == false
      puts ''
      pass.should eq(true)
    end
  end

  context "Copy content of #{existing_service_module_name} to new #{service_module_name} service module" do
    it "copies content of #{existing_service_module_name} to new #{service_module_name} service module" do
      puts "Copy content of #{existing_service_module_name} to new #{service_module_name} service module:", '-------------------------------------------------------------------------------'
      pass = false
      value = `cp -r #{service_filesystem_location}/#{existing_service_module_name}/* #{default_service_filesystem_location}/#{service_module_name}/`
      pass = !value.include?('No such file or directory')
      puts "Content of #{existing_service_module_name} copied to #{service_module_name} service successfully!" if pass == true
      puts "Content of #{existing_service_module_name} was not copied to #{service_module_name} service successfully!" if pass == false
      puts ''
      pass.should eq(true)
    end
  end

  context 'Import new service module function' do
    include_context 'Import service module', service_module_name
  end

  context 'Create new service module version' do
    include_context 'Create service module version', dtk_common, local_service_module_name, version
  end

  context 'Publish service module version to remote repo' do
    include_context 'Publish versioned service module', dtk_common, local_service_module_name, "#{namespace}/#{service_module_name}", version
  end

  context 'List all service modules on remote' do
    include_context 'List all service modules on remote', service_module_name, namespace
  end

  context 'Delete all service module version from server' do
    include_context 'Delete all service module versions', dtk_common, local_service_module_name
  end

  context 'Delete all local service module version files' do
    include_context 'Delete all local service module versions', local_service_filesystem_location, service_module_name
  end

  context 'Delete all service module version from server' do
    include_context 'Delete all service module versions', dtk_common, imported_service_module_name
  end

  context 'Delete all local service module version files' do
    include_context 'Delete all local service module versions', service_filesystem_location, existing_service_module_name
  end

  context 'Delete service module version from remote repo' do
    include_context 'Delete remote service module version', dtk_common, service_module_name, namespace, version
  end

  context 'Delete service module version from remote repo' do
    include_context 'Delete remote service module version', dtk_common, service_module_name, namespace, 'master'
  end

  after(:all) do
    puts '', ''
  end
end
