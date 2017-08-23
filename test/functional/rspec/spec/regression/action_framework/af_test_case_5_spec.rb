# Test Case 5: Service with one node that contains cmp with actions (unless/if/file position)
# This test script will test following: 
# - converge service instance with action module component
# - execute actions on node based on unless and if clauses

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'file-positioning-and-clauses'
service_name = 'af_test_case_5_instance'
module_location = '/tmp/action_module'
module_name = 'r8/action_module'
module_version = 'master'
service_location = '~/dtk/'
service_instance_location = '~/dtk/af_test_case_5_instance'
converge_error_message = "Permissions '0888' are not valid"

dtk_common = Common.new(service_name, assembly_name)

expected_output_1 = {
  command: 'mkdir /tmp/test1 && rm -rf /tmp/test1',
  status: 'succeeded',
  return_code: 0
}

expected_output_2 = {
  command: 'mkdir /tmp/test2 && rm -rf /tmp/test2',
  status: 'succeeded',
  return_code: 0
}

expected_output_3_1 = {
  command: '/tmp/test.txt with provided content',
  status: 'succeeded',
  return_code: 0
}

expected_output_3_2 = {
  command: 'cat /tmp/test.txt | grep newtest',
  status: 'succeeded',
  return_code: 0
}

expected_output_3_3 = {
  command: 'rm -rf /tmp/test.txt',
  status: 'succeeded',
  return_code: 0
}

expected_output_4_1 = {
  command: '/tmp/test.txt with provided content',
  status: 'succeeded',
  return_code: 0
}

expected_output_4_2 = {
  command: 'rm -rf /tmp/test.txt',
  status: 'succeeded',
  return_code: 0
}

expected_output_5 = {
  command: '/tmp/test.txt with provided content',
  status: 'failed',
  stderr: "Permissions '0888' are not valid"
}

describe '(Action Framework) Test Case 5: Service with one node that contains cmp with actions (unless/if/file position)' do
  before(:all) do
    puts '**************************************************************************************************************', ''
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

  context 'Get task status details for action with successfull if command' do
    include_context 'Get task status details', service_instance_location, "STAGE 2", [expected_output_1]
  end

  context 'Get task status details for action with successfull unless command' do
    include_context 'Get task status details', service_instance_location, "STAGE 3", [expected_output_2]
  end

  context 'Get task status details for action with successfull create file command' do
    include_context 'Get task status details', service_instance_location, "STAGE 4", [expected_output_3_1, expected_output_3_2, expected_output_3_3]
  end

  context 'Get task status details for action with successfull create file with permissions command' do
    include_context 'Get task status details', service_instance_location, "STAGE 5", [expected_output_4_1, expected_output_4_2]
  end

  context 'Get task status details for action with failed create command (fake permissions)' do
    include_context 'Get task status details', service_instance_location, "STAGE 6", [expected_output_5]
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
