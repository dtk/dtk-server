#!/usr/bin/env ruby
# Test Case 2: Add new target to existing provider, stage and converge assembly in this target and then delete target

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/target_spec'
require './lib/assembly_operations_spec'

STDOUT.sync = true

assembly_name = 'tp_test_case_2_instance'
assembly_template = 'bootstrap::test1'
provider_name = 'test_provider-template'
region = 'us-east-1'
target_name = "#{provider_name}-#{region}"

$assembly_id = 0
dtk_common = Common.new(assembly_name, assembly_template)

describe '(Targets and Providers) Test Case 2: Add new target to existing provider, stage and converge assembly in this target and then delete target' do
  before(:all) do
    puts '*******************************************************************************************************************************************'
    puts '(Targets and Providers) Test Case 2: Add new target to existing provider, stage and converge assembly in this target and then delete target'
    puts '*******************************************************************************************************************************************'
    puts ''
    end

  context 'Create target command' do
    include_context 'Create target', dtk_common, provider_name, region
  end

  context "Target #{provider_name}-#{region}" do
    include_context 'Check if target exists in provider', dtk_common, provider_name, target_name
  end

  context 'Stage assembly in specific target' do
      include_context 'Stage assembly in specific target', dtk_common, target_name
    end

    context 'Converge function' do
      include_context 'Converge', dtk_common
    end

  context 'Delete target command' do
    include_context 'Delete target', dtk_common, target_name
  end

  context "Target #{provider_name}-#{region}" do
    include_context 'NEG - Check if target exists in provider', dtk_common, provider_name, target_name
  end

  context 'List assemblies after delete of target' do
        include_context 'NEG - List assemblies', dtk_common
    end

  after(:all) do
    puts '', ''
  end
end
