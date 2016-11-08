#!/usr/bin/env ruby
# Test Case 3: Deploy from assembly (stage and converge), stop the running instance (nodes) and then delete service

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

module_name = 'newclient:bootstrap'
module_location = '~/modules/newclient/bootstrap'
service_location = "~/dtk/"
service_name = 'stda_test_case_3_instance'
assembly_name = 'node_with_params'
image = 'precise'
size = 'micro'
dtk_common = Common.new('', '')

describe '(Staging And Deploying Assemblies) Test Case 3: Deploy from assembly (stage and converge), stop the running instance (nodes) and then delete service' do
  before(:all) do
    puts '****************************************************************************************************************************************************', ''
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context 'List service instances after stage' do
    include_context 'List service instances after stage', dtk_common, service_name
  end

  context "Set attribute for ec2 image" do
    include_context "Set attribute", service_location, service_name, 'node1/image', image
  end

  context "Set attribute for ec2 size" do
    include_context "Set attribute", service_location, service_name, 'node1/size', size
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context 'Stop service instance' do
    include_context 'Stop service instance', dtk_common, service_location, service_name
  end

  context "Destroy service instance" do
    include_context "Destroy service instance", service_location, service_name
  end

  after(:all) do
    puts '', ''
  end
end
