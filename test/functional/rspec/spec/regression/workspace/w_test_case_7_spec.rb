#!/usr/bin/env ruby
# Test Case 7: Create attribute on workspace (list attributes), set value for this attribute and then unset the value and purge workspace

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'

STDOUT.sync = true

attribute_name = 'test'
attribute_value = '10'

dtk_common = DtkCommon.new('', '')

describe "(Workspace) Test Case 7: Create attribute on workspace (list attributes), set value for this attribute and then unset the value and purge workspace" do

	before(:all) do
		puts "***************************************************************************************************************************************************"
		puts "(Workspace) Test Case 7: Create attribute on workspace (list attributes), set value for this attribute and then unset the value and purge workspace"
		puts "***************************************************************************************************************************************************"
		puts ""
  	end

	context "Create attribute in workspace" do
		include_context "Create attribute in workspace", dtk_common, attribute_name
	end

	context "Set attribute value in workspace" do
		include_context "Set attribute value in workspace", dtk_common, attribute_name, attribute_value
	end	

	context "Purge workspace content" do
		include_context "Purge workspace content", dtk_common
	end	

	after(:all) do
		puts "", ""
	end
end