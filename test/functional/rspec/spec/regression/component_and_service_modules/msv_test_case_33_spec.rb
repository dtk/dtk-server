#!/usr/bin/env ruby
# Test Case 33: Import git to two different namespaces

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

component_module_name = "ntp"
git_ssh_repo_url = "git@github.com:puppetlabs/puppetlabs-ntp.git"
namespace_to_import_1 = "test_namespace_1"
namespace_to_import_2 = "test_namespace_2"
namespace_component_module_filesystem_location_1 = "~/dtk/component_modules/test_namespace_1"
namespace_component_module_filesystem_location_2 = "~/dtk/component_modules/test_namespace_2"

dtk_common = Common.new('', '')

describe "(Modules, Services and Versioning) Test Case 33: Import git to two different namespaces" do

  before(:all) do
    puts "***************************************************************************************",""
  end

  context "Import component module from git repo to specific namespace" do
    include_context "Import component module from provided git repo to specific namespace", component_module_name, git_ssh_repo_url, namespace_to_import_1
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", namespace_component_module_filesystem_location_1, component_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, namespace_to_import_1 + ":" + component_module_name
  end

  context "Import component module from git repo to specific namespace" do
    include_context "Import component module from provided git repo to specific namespace", component_module_name, git_ssh_repo_url, namespace_to_import_2
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", namespace_component_module_filesystem_location_2, component_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, namespace_to_import_2 + ":" + component_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, namespace_to_import_1 + ":" + component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", namespace_component_module_filesystem_location_1, component_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, namespace_to_import_2 + ":" + component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", namespace_component_module_filesystem_location_2, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end