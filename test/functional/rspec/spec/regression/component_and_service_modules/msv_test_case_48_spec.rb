#!/usr/bin/env ruby
# Test Case 48: List component, service and test modules on local and remote with filter

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'
require './lib/component_modules_spec'
require './lib/test_modules_spec'

existing_modules_namespace_filter = "r8"
non_existing_modules_namespace_filter = "non_existing_namespace"
dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 48: List component, service and test modules on local and remote with filter" do
  before(:all) do
    puts "*************************************************************************************************************************",""
  end

  context "List component modules with filter" do
    include_context "List component modules with filter", dtk_common, existing_modules_namespace_filter
  end

  context "List test modules with filter" do
    include_context "List test modules with filter", dtk_common, existing_modules_namespace_filter
  end

  context "List service modules with filter" do
    include_context "List service modules with filter", dtk_common, existing_modules_namespace_filter
  end

  context "List component modules with non existing filter" do
    include_context "NEG - List component modules with filter", dtk_common, non_existing_modules_namespace_filter
  end

  context "List test modules with non existing filter" do
    include_context "NEG - List test modules with filter", dtk_common, non_existing_modules_namespace_filter
  end

  context "List service modules with non existing filter" do
    include_context "NEG - List service modules with filter", dtk_common, non_existing_modules_namespace_filter
  end

  context "List component modules with filter on remote" do
    include_context "List component modules with filter on remote", dtk_common, existing_modules_namespace_filter
  end

  context "List test modules with filter on remote" do
    include_context "List test modules with filter on remote", dtk_common, existing_modules_namespace_filter
  end

  context "List service modules with filter on remote" do
    include_context "List service modules with filter on remote", dtk_common, existing_modules_namespace_filter
  end

  context "List component modules with non existing filter on remote" do
    include_context "NEG - List component modules with filter on remote", dtk_common, non_existing_modules_namespace_filter
  end

  context "List test modules with non existing filter on remote" do
    include_context "NEG - List test modules with filter on remote", dtk_common, non_existing_modules_namespace_filter
  end

  context "List service modules with non existing filter on remote" do
    include_context "NEG - List service modules with filter on remote", dtk_common, non_existing_modules_namespace_filter
  end

  after(:all) do
    puts "", ""
  end
end
