#!/usr/bin/env ruby
#Test Case 5: Check possibility to create assembly template from existing assembly and then to converge new assembly template

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec.rb'

assembly_name = 'test_case_5_instance'
assembly_template = 'bootstrap::test1'
new_assembly_name = 'test_case_5_instance2'
new_assembly_template = 'test_case_5_temp'
service_name = 'bootstrap'

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name, assembly_template)
dtk_common2 = DtkCommon.new(new_assembly_name, "#{service_name}::#{new_assembly_template}")

puts "****************************************************************************************************************************"
puts "Test Case 5: Check possibility to create assembly template from existing assembly and then to converge new assembly template"
puts "****************************************************************************************************************************"

describe "Test Case 5: Check possibility to create assembly template from existing assembly and then to converge new assembly template" do

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

  context "Converge function" do
    include_context "Converge", dtk_common2
  end

  context "Delete and destroy assembly function" do
    include_context "Delete assemblies", dtk_common2
  end

  context "Delete assembly template function" do
    include_context "Delete assembly template", dtk_common2, "#{service_name}::#{new_assembly_template}"
  end
end

puts "", ""