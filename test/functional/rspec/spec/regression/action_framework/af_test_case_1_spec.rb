# Test Case 1: Service with one node that contains cmp with actions with multiple commands in it
# This test script will test following: 
# - converge service instance with action module component
# - execute actions that contain multiple successful and multiple failure commands

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'multiple-commands'
service_name = 'af_test_case_1_instance'
module_location = '/tmp/action_module'
module_name = 'r8/action_module'
module_version = 'master'
service_location = '~/dtk/'
service_instance_location = '~/dtk/af_test_case_1_instance'
converge_error_message = 'ls: cannot access /some/non/existing/location: No such file or directory'

dtk_common = Common.new(service_name, assembly_name)

expected_output_1_1 = {
  command: 'ls -l /usr/share/dtk',
  status: 'succeeded',
  return_code: 0
}

expected_output_1_2 = {
  command: 'ls /usr',
  status: 'succeeded',
  return_code: 0
}

expected_output_2_1 = {
  command: 'ls -l /some/non/existing/location',
  status: 'failed',
  stderr: 'ls: cannot access /some/non/existing/location: No such file or directory'
}

describe '(Action Framework) Test Case 1: Service with one node that contains cmp with actions with multiple commands in it' do
  before(:all) do
    puts '*****************************************************************************************************************', ''
    # Install/clone r8:action_module module with required dependency modules if needed
    location_exist = system("ls #{module_location}")
    unless location_exist
      system("mkdir #{module_location}")
      system("dtk module clone -v #{module_version} #{module_name} #{module_location}")
      system("dtk module install --update-deps -d #{module_location} #{module_name}")
    end
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "NEG - Converge service instance" do
    include_context "NEG - Converge service instance", service_location, dtk_common, service_name, converge_error_message
  end

  context 'Get task status details for action with two successfull commands' do
    include_context 'Get task status details', service_instance_location, "STAGE 3", [expected_output_1_1, expected_output_1_2]
  end

  context 'Get task status details for action with two failure commands' do
    include_context 'Get task status details', service_instance_location, "STAGE 4", [expected_output_2_1]
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
