#!/usr/bin/env ruby
# Test Case 32: Set default namespace, do import and import-git, revert back to original namespace and do import, import-git again

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

default_namespace = 'local'
new_default_namespace = 'new_namespace'
existing_component_module = 'r8:apache'
existing_component_module_name = 'apache'
existing_namespace = 'r8'
component_module_name = 'tftp'
git_ssh_repo_url = 'git@github.com:puppetlabs/puppetlabs-tftp.git'
default_filesystem_location = '~/dtk/component_modules'
r8_component_module_filesystem_location = '~/dtk/component_modules/r8'
new_component_module_filesystem_location = '~/dtk/component_modules/new_namespace'
local_component_module_filesystem_location = '~/dtk/component_modules/local'

dtk_common = DtkCommon.new('', '')

describe '(Modules, Services and Versioning) Test Case 32: Set default namespace, do import and import-git, revert back to original namespace and do import, import-git again' do
  before(:all) do
    puts '*******************************************************************************************************************************************************************', ''
  end

  context 'Set new default namespace' do
    include_context 'Set default namespace', dtk_common, new_default_namespace
  end

  context 'Import component module function' do
    include_context 'Import remote component module', existing_namespace + '/' + existing_component_module_name
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, existing_component_module
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', r8_component_module_filesystem_location, existing_component_module_name
  end

  context "Create new directory called #{existing_component_module_name} and copy the content of #{existing_component_module} in it" do
    it 'creates new directory with existing component module content in it' do
      puts 'Create new directory and copy the content of existing component module', '----------------------------------------------------------------------'
      pass = false
      `mkdir -p #{default_filesystem_location}/#{existing_component_module_name}`
      `cp -r #{r8_component_module_filesystem_location}/#{existing_component_module_name}/* #{default_filesystem_location}/#{existing_component_module_name}/`
      value = `ls #{default_filesystem_location}/#{existing_component_module_name}/manifests`
      pass = !value.include?('No such file or directory')
      puts ''
      pass.should eq(true)
    end
  end

  context 'Import new component module function' do
    include_context 'Import component module', existing_component_module_name
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', new_component_module_filesystem_location, existing_component_module_name
  end

  context 'Import component module from git repo' do
    include_context 'Import component module from provided git repo', component_module_name, git_ssh_repo_url
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', new_component_module_filesystem_location, component_module_name
  end

  context 'Revert old default namespace' do
    include_context 'Set default namespace', dtk_common, default_namespace
  end

  context "Create new directory called #{existing_component_module_name} and copy the content of #{existing_component_module} in it" do
    it 'creates new directory with existing component module content in it' do
      puts 'Create new directory and copy the content of existing component module', '----------------------------------------------------------------------'
      pass = false
      `mkdir -p #{default_filesystem_location}/#{existing_component_module_name}`
      `cp -r #{r8_component_module_filesystem_location}/#{existing_component_module_name}/* #{default_filesystem_location}/#{existing_component_module_name}/`
      value = `ls #{default_filesystem_location}/#{existing_component_module_name}/manifests`
      pass = !value.include?('No such file or directory')
      puts ''
      pass.should eq(true)
    end
  end

  context 'Import new component module function' do
    include_context 'Import component module', existing_component_module_name
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', local_component_module_filesystem_location, existing_component_module_name
  end

  context 'Import component module from git repo' do
    include_context 'Import component module from provided git repo', component_module_name, git_ssh_repo_url
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', local_component_module_filesystem_location, component_module_name
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, existing_component_module
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', r8_component_module_filesystem_location, existing_component_module_name
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, new_default_namespace + ':' + existing_component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', new_component_module_filesystem_location, existing_component_module_name
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, default_namespace + ':' + existing_component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', local_component_module_filesystem_location, existing_component_module_name
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, new_default_namespace + ':' + component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', new_component_module_filesystem_location, component_module_name
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, default_namespace + ':' + component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', local_component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts '', ''
  end
end
