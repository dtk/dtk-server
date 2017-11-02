#!/usr/bin/env ruby
# Test Case 7: Using lambda function in dtk.model.yaml
# This test script will test following: 
# - converge service instance with component that contains ruby lambda that will be executed

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'lambda'
service_name = 'af_test_case_7_instance'
module_location = '/tmp/module_with_lambda'
module_name = 'r8/module_with_lambda'
module_version = 'master'
service_location = '~/dtk/'
service_instance_location = '~/dtk/af_test_case_7_instance'

dtk_common = Common.new(service_name, assembly_name)

expected_output_1 = {
  command: 'cat /tmp/test | grep 55',
  status: 'succeeded',
  return_code: 0
}

describe '(Action Framework) Test Case 7: Using lambda function in dtk.model.yaml' do
  before(:all) do
    puts '***********************************************************************', ''
    # Install r8:module_with_lambda module with required dependency modules if needed
    location_exist = system("ls #{module_location}")
    unless location_exist
      system("mkdir #{module_location}")
      system("dtk module install --update-deps -d #{module_location} #{module_name}")
    end
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Get task status details for action with bash script command" do
    include_context 'Get task status details', service_instance_location, "STAGE 4", [expected_output_1]
  end

  context "Delete service instance" do
    include_context "Delete service instance", service_location, service_name, dtk_common
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  after(:all) do
    puts '', ''
  end
end