# Test Case 3: Service with two nodes that contain cmp with actions with parametrized commands (mustache)
# This test script will test following: 
# - converge service instance with action module component
# - execute actions on multiple nodes
# - check if mustache variables are resolved in action commands

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'multi-node-with-mustache'
service_name = 'af_test_case_3_instance'
module_location = '/tmp/action_module'
module_name = 'r8/action_module'
module_version = 'master'
service_location = '~/dtk/'
service_instance_location = '~/dtk/af_test_case_3_instance'

dtk_common = Common.new(service_name, assembly_name)

expected_output_1 = {
  command: 'ls /usr/share/dtk',
  status: 'succeeded',
  return_code: 0
}

expected_output_2_1 = {
  command: 'ls -l /usr/share/dtk',
  status: 'succeeded',
  return_code: 0
}

expected_output_2_2 = {
  command: 'ls -a /usr/share/dtk',
  status: 'succeeded',
  return_code: 0
}

describe '(Action Framework) Test Case 3: Service with two nodes that contain cmp with actions with parametrized commands (mustache)' do
  before(:all) do
    puts '************************************************************************************************************************', ''
    # Install r8:action_module module with required dependency modules if needed
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

  context 'Get task status details for action with one successfull command' do
    include_context 'Get task status details', service_instance_location, "STAGE 5", [expected_output_1]
  end

  context 'Get task status details for action with two successfull commands' do
    include_context 'Get task status details', service_instance_location, "STAGE 6", [expected_output_2_1, expected_output_2_2]
  end

  context 'Get task status details for action with one successfull command' do
    include_context 'Get task status details', service_instance_location, "STAGE 7", [expected_output_1]
  end

  context 'Get task status details for action with two successfull commands' do
    include_context 'Get task status details', service_instance_location, "STAGE 8", [expected_output_2_1, expected_output_2_2]
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
