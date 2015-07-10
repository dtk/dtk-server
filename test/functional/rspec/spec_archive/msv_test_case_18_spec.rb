#!/usr/bin/env ruby
# Test Case 18: NEG - Import module from puppet forge with incorrect puppet module name

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

puppet_forge_module_name = 'puppetlabs-ruby-incorrect'
module_name = 'ruby'
module_filesystem_location = '~/component_modules'
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe '(Modules, Services and Versioning) Test Case 18: NEG - Import module from puppet forge with incorrect puppet module name' do
  before(:all) do
    puts '************************************************************************************************************************'
    puts '(Modules, Services and Versioning) Test Case 18: NEG - Import module from puppet forge with incorrect puppet module name'
    puts '************************************************************************************************************************'
  end

  context 'Import incorrect module from puppet forge' do
    include_context 'NEG - Import module from puppet forge', puppet_forge_module_name
  end

  context 'Get module components list' do
    include_context 'NEG - Get module components list', dtk_common, module_name
  end

  after(:all) do
    puts '', ''
  end
end
