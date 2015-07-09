#!/usr/bin/env ruby
# Test Case 39: Import to two differenet namespaces (service module)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'

namespace = 'r8'
service_module_name = 'test_service_module'
service_module = 'r8:test_service_module'
new_service_module = 'test:test_service_module'
new_service_module_2 = 'test2:test_service_module'
default_filesystem_location = '~/dtk/service_modules'
r8_service_module_filesystem_location = '~/dtk/service_modules/r8'
test_service_module_filesystem_location = '~/dtk/service_modules/test'
test2_service_module_filesystem_location = '~/dtk/service_modules/test2'

dtk_common = DtkCommon.new('', '')

describe '(Modules, Services and Versioning) Test Case 39: Import to two different namespaces (service module)' do
  before(:all) do
    puts '****************************************************************************************************',''
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

  context "Create new directory called #{service_module_name} and copy the content of #{service_module} in it" do
    it 'creates new directory with existing component module content in it' do
      puts 'Create new directory and copy the content of existing component module', '----------------------------------------------------------------------'
      pass = false
      `mkdir -p #{test_service_module_filesystem_location}/#{service_module_name}`
      `cp -r #{r8_service_module_filesystem_location}/#{service_module_name}/* #{test_service_module_filesystem_location}/#{service_module_name}/`
      value = `ls #{test_service_module_filesystem_location}/#{service_module_name}/manifests`
      pass = !value.include?('No such file or directory')
      puts ''
      pass.should eq(true)
    end
  end

  context 'Import new service module function' do
    include_context 'Import service module', new_service_module
  end

  context 'List all service modules' do
    include_context 'List all service modules', dtk_common, new_service_module
  end

  context 'Check if service module imported on local filesystem' do
    include_context 'Check service module imported on local filesystem', test_service_module_filesystem_location, service_module_name
  end

  context "Create new directory called #{service_module_name} and copy the content of #{service_module} in it" do
    it 'creates new directory with existing component module content in it' do
      puts 'Create new directory and copy the content of existing component module', '----------------------------------------------------------------------'
      pass = false
      `mkdir -p #{test2_service_module_filesystem_location}/#{service_module_name}`
      `cp -r #{r8_service_module_filesystem_location}/#{service_module_name}/* #{test2_service_module_filesystem_location}/#{service_module_name}/`
      value = `ls #{test2_service_module_filesystem_location}/#{service_module_name}/manifests`
      pass = !value.include?('No such file or directory')
      puts ''
      pass.should eq(true)
    end
  end

  context 'Import new service module function' do
    include_context 'Import service module', new_service_module_2
  end

  context 'List all service modules' do
    include_context 'List all service modules', dtk_common, new_service_module_2
  end

  context 'Check if service module imported on local filesystem' do
    include_context 'Check service module imported on local filesystem', test2_service_module_filesystem_location, service_module_name
  end

  context 'Delete service module' do
    include_context 'Delete service module', dtk_common, service_module
  end

  context 'Delete service module from local filesystem' do
    include_context 'Delete service module from local filesystem', r8_service_module_filesystem_location, service_module_name
  end

  context 'Delete service module' do
    include_context 'Delete service module', dtk_common, new_service_module
  end

  context 'Delete service module from local filesystem' do
    include_context 'Delete service module from local filesystem', test_service_module_filesystem_location, service_module_name
  end

  context 'Delete service module' do
    include_context 'Delete service module', dtk_common, new_service_module_2
  end

  context 'Delete service module from local filesystem' do
    include_context 'Delete service module from local filesystem', test2_service_module_filesystem_location, service_module_name
  end

  after(:all) do
    puts '', ''
  end
end
