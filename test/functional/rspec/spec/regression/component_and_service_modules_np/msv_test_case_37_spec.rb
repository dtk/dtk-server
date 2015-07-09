#!/usr/bin/env ruby
# Test Case 37: NEG - Install component module from r8 namespace, but local copy of this module already exists and it is in r8 namespace

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

default_namespace = 'local'
new_default_namespace = 'r8'

component_module_name = 'wget'
component_module = 'r8:wget'
git_ssh_repo_url = 'git@github.com:maestrodev/puppet-wget.git'
r8_component_module_filesystem_location = '~/dtk/component_modules/r8'

dtk_common = DtkCommon.new('', '')

describe '(Modules, Services and Versioning) Test Case 37: NEG - Install component module from r8 namespace, but local copy of this module already exists and it is in r8 namespace' do
  before(:all) do
    puts '*************************************************************************************************************************************************************************',''
  end

  context 'Set new default namespace' do
    include_context 'Set default namespace', dtk_common, new_default_namespace
  end

  context 'Import component module from git repo' do
    include_context 'Import component module from provided git repo', component_module_name, git_ssh_repo_url
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, component_module
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', r8_component_module_filesystem_location, component_module_name
  end

  context 'Import component module from remote' do
    include_context 'NEG - Import remote component module', new_default_namespace + '/' + component_module_name
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, component_module
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', r8_component_module_filesystem_location, component_module_name
  end

  context 'Revert old default namespace' do
    include_context 'Set default namespace', dtk_common, default_namespace
  end

  after(:all) do
    puts '', ''
  end
end
