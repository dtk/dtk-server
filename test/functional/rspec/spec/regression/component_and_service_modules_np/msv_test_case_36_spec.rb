#!/usr/bin/env ruby
# Test Case 36: Install service module, publish to different namespace and install it again

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'
require './lib/service_module_versions_spec'

namespace = 'r8'
service_module_name = 'test_service_module'
service_module = 'r8:test_service_module'
new_service_module = 'dtk17:test_service_module'
new_namespace = 'dtk17'
r8_service_module_filesystem_location = '~/dtk/service_modules/r8'
dtk17_service_module_filesystem_location = '~/dtk/service_modules/dtk17'
version = '0.0.1'

dtk_common = Common.new('', '')

describe '(Modules, Services and Versioning) Test Case 36: Install service module, publish to different namespace and install it again' do
  before(:all) do
    puts '****************************************************************************************************************************', ''
  end

  context 'Import service module function' do
    include_context 'Import remote service module', namespace + '/' + service_module_name
  end

  context 'List all service modules' do
    include_context 'List all service modules', dtk_common, service_module
  end

  context 'Check if service module imported on local filesystem' do
    include_context 'Check service module imported on local filesystem', r8_service_module_filesystem_location, service_module_name
  end

  context 'Create new service module version' do
    include_context 'Create service module version', dtk_common, service_module, version
  end

  context 'Publish service module version to remote repo' do
    include_context 'Publish versioned service module', dtk_common, service_module, "#{namespace}/#{service_module_name}", version
  end

  context 'Import previously published service module' do
    include_context 'Import remote service module', new_namespace + '/' + service_module_name
  end

  context 'List all service modules' do
    include_context 'List all service modules', dtk_common, new_service_module
  end

  context 'Check if service module imported on local filesystem' do
    include_context 'Check service module imported on local filesystem', dtk17_service_module_filesystem_location, service_module_name
  end

  context 'Delete all service module version from server' do
    include_context 'Delete all service module versions', dtk_common, service_module
  end

  context 'Delete all local service module version files' do
    include_context 'Delete all local service module versions', r8_service_module_filesystem_location, service_module_name
  end

  context 'Delete all service module version from server' do
    include_context 'Delete all service module versions', dtk_common, new_service_module
  end

  context 'Delete all local service module version files' do
    include_context 'Delete all local service module versions', dtk17_service_module_filesystem_location, service_module_name
  end

  context 'Delete service module version from remote repo' do
    include_context 'Delete remote service module version', dtk_common, service_module_name, new_namespace, version
  end

  context "Delete #{service_module_name} service module from remote" do
    include_context 'Delete service module from remote repo', service_module_name, new_namespace
  end

  after(:all) do
    puts '', ''
  end
end
