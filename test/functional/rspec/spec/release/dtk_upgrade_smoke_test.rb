#!/usr/bin/env ruby
# This is DTK Server smoke test used for execution in DTK Release process

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require File.join(File.dirname(__FILE__), '../..', 'lib/dtk_common')
require File.join(File.dirname(__FILE__), '../..', 'lib/assembly_and_service_operations_spec')
require File.join(File.dirname(__FILE__), '../..', 'lib/parameters_setting_spec')
require File.join(File.dirname(__FILE__), '../..', 'lib/component_modules_spec')
require File.join(File.dirname(__FILE__), '../..', 'lib/service_modules_spec')

# assuming that the tenant is already linked to repoman
catalog_username = "public-internal"
catalog_password = "905^03N#V!a0"
tenant_server = ENV['tenant_server'] || "dtk1.dtk.io"
tenant_username = ENV['username'] || "dtk1"
tenant_password = ENV['tenant_password'] || "password"
service_name = 'dtk_release_smoke_test'
assembly_name = 'test_service::node_with_params'
os_templates = ['precise']
os_attribute = 'os_identifier'
memory_size = 't1.micro'
memory_size_attribute = 'memory_size'
node_name = 'node1'
component_module_name = "test_module"
local_component_module_name = 'internal:test_module'
service_module_name = "test_service"
local_service_module_name = 'internal:test_service'
namespace = 'internal'
# local_default_namespace = 'dtk16'
component_module_filesystem_location = "~/dtk/component_modules"
rvm_path = "/usr/local/rvm/wrappers/default/"

dtk_common = DtkCommon.new(service_name, assembly_name)
dtk_common.server = tenant_server
dtk_common.endpoint = "https://#{tenant_server}:443"
dtk_common.username = tenant_username
dtk_common.password = tenant_password
dtk_common.login

describe "DTK Server smoke test release" do
  before(:all) do
    puts "*****************************",""
  end

  context "Set catalog credentials" do
    include_context "Set catalog credentials", dtk_common, catalog_username, catalog_password
  end

  context "Install service module" do
    include_context "Import remote service module", namespace + ':' + service_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, local_component_module_name
  end

  os_templates.each do |os|
    context "Stage service function on #{assembly_name} assembly" do
      include_context "Stage", dtk_common
    end

    context "List services after stage" do
      include_context "List services after stage", dtk_common
    end

    context "Set os attribute function" do
      include_context "Set attribute", dtk_common, os_attribute, os
    end

    context "Set memory size attribute function" do
      include_context "Set attribute", dtk_common, memory_size_attribute, memory_size
    end

    #    context "Converge function" do
    #      include_context "Converge service", dtk_common, 30
    #    end

    context "Delete and destroy service function" do
      include_context "Delete services", dtk_common
    end
  end

  context "Delete service module function" do
    include_context "Delete service module", dtk_common, local_service_module_name
  end

  context "Delete component module function" do
    include_context "Delete component module", dtk_common, local_component_module_name
  end

  # context "Delete #{component_module_name} component module from remote" do
  #   include_context "Delete component module from remote repo rvm", rvm_path, dtk_common, component_module_name, namespace
  # end

  #  context "Delete #{service_module_name} service module from remote" do
  #    include_context "Delete service module from remote repo rvm", rvm_path, dtk_common, service_module_name, namespace
  #  end

  after(:all) do
    puts "", ""
  end
end
