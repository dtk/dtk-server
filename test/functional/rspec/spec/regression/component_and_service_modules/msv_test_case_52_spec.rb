#!/usr/bin/env ruby
# Test Case 52: Import Puppet Forge (maven) but there are multiple (ambiguous) wget dependencies (maestrodev/wget, r8/wget)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

puppet_forge_module_name = "maestrodev-maven"
module_name = "maven"
component_module_name = "maestrodev:maven"
dependency_module_name = "wget"
dependency_component_module_name = "maestrodev:wget"
dependency_component_module_name_2 = "r8:wget"
git_ssh_repo_url = "git@github.com:maestrodev/puppet-wget.git"
namespace_1 = "maestrodev"
namespace_2 = "r8"
component_module_filesystem_location = '~/dtk/component_modules/maestrodev'
component_module_filesystem_location_2 = '~/dtk/component_modules/r8'
grep_patterns_for_module_refs = ['wget:','namespace: maestrodev']
dtk_common = Common.new('', '')

describe "(Modules, Services and Versioning) Test Case 52: Import Puppet Forge (maven) but there are multiple (ambiguous) wget dependencies (maestrodev/wget, r8/wget)" do

  before(:all) do
    puts "**********************************************************************************************************************************************************",""
  end

  context "Import component module from git repo to specific namespace" do
    include_context "Import component module from provided git repo to specific namespace", dependency_module_name, git_ssh_repo_url, namespace_1
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, dependency_component_module_name
  end

  context "Import component module from git repo to specific namespace" do
    include_context "Import component module from provided git repo to specific namespace", dependency_module_name, git_ssh_repo_url, namespace_2
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, dependency_component_module_name_2
  end

  context "Import module from puppet forge" do
    include_context "Import module from puppet forge", puppet_forge_module_name, nil
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, component_module_name
  end

  context "Check module_refs.yaml for imported module" do
    include_context "Check module_refs.yaml for imported module", component_module_filesystem_location + "/" + module_name, grep_patterns_for_module_refs
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, dependency_component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, dependency_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, dependency_component_module_name_2
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location_2, dependency_module_name
  end

  after(:all) do
    puts "", ""
  end
end