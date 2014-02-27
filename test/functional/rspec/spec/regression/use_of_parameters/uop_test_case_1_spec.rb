#!/usr/bin/env ruby
#Test Case 1: Check possibility to create assembly template from existing assembly and then to converge new assembly template

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec.rb'

assembly_name = 'uop_test_case_1_instance'
assembly_template = 'bootstrap::node_with_params'
new_assembly_name = 'uop_test_case_1_instance2'
new_assembly_template = 'uop_test_case_1_temp'
service_name = 'bootstrap'

os_attribute = 'os_identifier'
memory_size_attribute = 'memory_size'
os = 'precise'
memory_size = 't1.micro'

dtk_common = DtkCommon.new(assembly_name, assembly_template)
dtk_common2 = DtkCommon.new(new_assembly_name, "#{service_name}::#{new_assembly_template}")

describe "(Use Of Parameters) Test Case 1: Check possibility to create assembly template from existing assembly and then to converge new assembly template" do

  before(:all) do
    puts "************************************************************************************************************************************************"
    puts "(Use Of Parameters) Test Case 1: Check possibility to create assembly template from existing assembly and then to converge new assembly template"
    puts "************************************************************************************************************************************************"
    puts ""
  end

  context "Stage assembly function on #{assembly_template} assembly template" do
    include_context "Stage", dtk_common
  end

  context "List assemblies after stage" do    
    include_context "List assemblies after stage", dtk_common
  end

  context "Create new assembly template from existing assembly" do
    include_context "Create assembly template from assembly", dtk_common, service_name, new_assembly_template
  end

  context "Delete and destroy assembly function" do
    include_context "Delete assemblies", dtk_common
  end

  context "Stage new assembly function on #{assembly_template} assembly template" do
    include_context "Stage", dtk_common2
  end

  context "List assemblies after stage of new assembly" do 
    include_context "List assemblies after stage", dtk_common2
  end

  context "Set os attribute function" do
    include_context "Set attribute", dtk_common2, os_attribute, os
  end

  context "Set memory size attribute function" do
    include_context "Set attribute", dtk_common2, memory_size_attribute, memory_size
  end

  context "Converge function" do
    include_context "Converge", dtk_common2
  end

  context "Delete and destroy assembly function" do
    include_context "Delete assemblies", dtk_common2
  end

  context "Delete assembly template function" do
    include_context "Delete assembly template", dtk_common2, "#{service_name}::#{new_assembly_template}"
  end

  after(:all) do
    puts "", ""
  end
end