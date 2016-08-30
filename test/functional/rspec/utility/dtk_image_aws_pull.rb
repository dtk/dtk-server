#!/usr/bin/env ruby
# This script is used to pull latest aws:image_aws images to current environment

require './lib/dtk_common'
require './lib/component_modules_spec'

component_module_name = 'aws:image_aws'
dtk_common = Common.new('', '')

describe 'Pull aws:image_aws from repoman' do
  context "Pull-dtkn component module" do
    include_context "Pull-dtkn component module", component_module_name
  end
end