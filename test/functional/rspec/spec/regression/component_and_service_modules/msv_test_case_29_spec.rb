#!/usr/bin/env ruby
# Test Case 29: Import component module A and then component module B when component module B has dependency on component module A

require 'rubygems'
require 'active_record'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'
require './lib/component_modules_spec'

component_module_name_1 = 'puppi'
git_ssh_repo_url_1 = 'git@github.com:example42/puppi.git'
local_component_module_name_1 = 'local:puppi'
component_module_name_2 = 'yum'
git_ssh_repo_url_2 = 'git@github.com:example42/puppet-yum.git'
local_component_module_name_2 = 'local:yum'
component_module_filesystem_location = '~/dtk/component_modules/local'

dtk_common = Common.new('', '')

describe '(Modules, Services and Versioning) Test Case 29: Import component module A and then component module B when component module B has dependency on component module A' do
  before(:all) do
    puts '*******************************************************************************************************************************************************************', ''
  end

  context 'Import component module from git repo' do
    include_context 'Import component module from provided git repo', component_module_name_1, git_ssh_repo_url_1
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', component_module_filesystem_location, component_module_name_1
  end

  context 'Import component module from git repo' do
    include_context 'Import component module from provided git repo', component_module_name_2, git_ssh_repo_url_2
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', component_module_filesystem_location, component_module_name_2
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, local_component_module_name_1
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module_name_1
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, local_component_module_name_2
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module_name_2
  end

  after(:all) do
    puts '', ''
  end
end
