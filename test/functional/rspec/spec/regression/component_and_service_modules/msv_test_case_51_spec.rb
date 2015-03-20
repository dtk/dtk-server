#!/usr/bin/env ruby
# Test Case 51: Import puppet forge (confluence) but its dependency (mkrakowitzer:deploy) is already installed on server

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

puppet_forge_module_name = "maestrodev-confluence"
module_name = "confluence"
component_module_name = "maestrodev:confluence"
dependency_module_name = "deploy"
dependency_component_module_name = "mkrakowitzer:deploy"
git_ssh_repo_url = "git@github.com:mkrakowitzer/puppet-deploy.git"
namespace = "mkrakowitzer"
component_module_filesystem_location = '~/dtk/component_modules/maestrodev'
grep_patterns_for_module_refs = ['deploy:','namespace: mkrakowitzer']
dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 51: Import puppet forge (confluence) but its dependency (mkrakowitzer:deploy) is already installed on server" do

  before(:all) do
    puts "*********************************************************************************************************************************************************",""
  end

  context "Import component module from git repo to specific namespace" do
    include_context "Import component module from provided git repo to specific namespace", dependency_module_name, git_ssh_repo_url, namespace
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, dependency_component_module_name
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
  
  after(:all) do
    puts "", ""
  end
end