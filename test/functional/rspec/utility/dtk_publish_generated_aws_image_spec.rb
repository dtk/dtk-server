#!/usr/bin/env ruby
# This RSpec script is used for generating new aws:image_aws component module version and publihsing it

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'

target_name = 'target'
workspace_assembly_template = 'workspace'
module_dir = '~/dtk'
namespace = 'aws'
ec2_component_module_name = 'ec2'
image_component_module_name = 'image_aws'
image_component_module_file = 'dtk.model.yaml'
full_component_module_name = "#{namespace}:#{image_component_module_name}"

dtk_common = Common.new('', '')

describe "DTK image lifecycle publish component module" do
  before(:all) do
    puts "********************************************"
  end

  context "Generate new component-module version" do
    include_context 'Generate component module version', dtk_common, full_component_module_name
  end

  context "Publish generated component-module version" do
    include_context 'Publish latest component module version', dtk_common, full_component_module_name
  end

  context "Check remote repository for published component-module version" do
    include_context 'Check if local latest version exists on remote', dtk_common, full_component_module_name
  end

  after(:all) do
    puts '',''
  end
end