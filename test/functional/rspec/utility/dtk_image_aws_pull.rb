#!/usr/bin/env ruby
# This script is used to pull latest aws:image_aws images to current environment

require './lib/dtk_common'
require './lib/component_modules_spec'
require './lib/service_modules_spec'

component_1 = 'aws:image_aws'
component_2 = 'aws:identity_aws'
component_3 = 'aws:ec2'
component_4 = 'aws:image_aws'
service = 'aws:network'
dtk_common = Common.new('', '')

describe 'Pull aws:image_aws from repoman' do
  context "Pull-dtkn component module" do
    include_context "Pull-dtkn component module", component_1
  end

  context "Pull-dtkn component module" do
    include_context "Pull-dtkn component module", component_2
  end

  context "Pull-dtkn component module" do
    include_context "Pull-dtkn component module", component_3
  end

  context "Pull-dtkn component module" do
    include_context "Pull-dtkn component module", component_4
  end

  context "Pull-dtkn service module" do
    include_context "Pull-dtkn service module", service
  end
end