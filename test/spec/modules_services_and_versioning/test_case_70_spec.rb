#!/usr/bin/env ruby
#Test Case 70: NEG - Import module from incorrect git repo url

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

module_name = "ruby"
git_ssh_repo_url = "git@github.com:puppetlabs/puppetlabs-ruby.git-incorrect"
module_filesystem_location = "~/dtk/component_modules"
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "Test Case 70: NEG - Import module from incorrect git repo url" do

  before(:all) do
    puts "*************************************************************"
    puts "Test Case 70: NEG - Import module from incorrect git repo url"
    puts "*************************************************************"
    puts ""
  end

  context "Create module from incorrect git repo" do
    include_context "NEG - Create module from provided git repo", module_name, git_ssh_repo_url
  end

  context "Get module components list" do
    include_context "NEG - Get module components list", dtk_common, module_name
  end

  after(:all) do
    puts "", ""
  end
end