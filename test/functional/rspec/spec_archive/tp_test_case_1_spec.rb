#!/usr/bin/env ruby
# Test Case 1: Add new target to existing provider, list targets and then delete target

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/target_spec'

STDOUT.sync = true

provider_name = "test_provider-template"
region = "us-east-1"
target_name = "#{provider_name}-#{region}"
dtk_common = Common.new('', '')

describe "(Targets and Providers) Test Case 1: Add new target to existing provider, list targets and then delete target" do

	before(:all) do
		puts "*************************************************************************************************************"
		puts "(Targets and Providers) Test Case 1: Add new target to existing provider, list targets and then delete target"
		puts "*************************************************************************************************************"
		puts ""
  	end

	context "Create target command" do
		include_context "Create target", dtk_common, provider_name, region
	end

	context "Target #{provider_name}-#{region}" do		
		include_context "Check if target exists in provider", dtk_common, provider_name, target_name
	end

	context "Delete target command" do
		include_context "Delete target", dtk_common, target_name
	end

	context "Target #{provider_name}-#{region}" do		
		include_context "NEG - Check if target exists in provider", dtk_common, provider_name, target_name
	end

	after(:all) do
		puts "", ""
	end
end