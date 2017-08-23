# Test Case 6: Service with five nodes that containt cmp with actions for tailing in nohup
# This test script will test following: 
# - converge service instance with action module component
# - execute actions on node which has nohup tail command

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'nohup-log-tailing'
service_name = 'af_test_case_6_instance'
module_location = '/tmp/action_module'
module_name = 'r8/action_module'
module_version = 'master'
service_location = '~/dtk/'
service_instance_location = '~/dtk/af_test_case_6_instance'

dtk_common = Common.new(service_name, assembly_name)

expected_output_1 = {
  command: 'nohup tail -f /var/log/dtk/dtk-arbiter.output',
  status: 'succeeded',
  return_code: 0
}

node_images=['trusty_hvm','amazon_hvm','xenial_hvm']

describe '(Action Framework) Test Case 6: Service with five nodes that containt cmp with actions for tailing in nohup' do
  before(:all) do
	  puts '************************************************************************************************************************', ''
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

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Get task status details for action executed on #{node_images[0]} node" do
    include_context 'Get task status details', service_instance_location, "STAGE 4", [expected_output_1]
  end

  context "Get task status details for action executed on #{node_images[1]} node" do
    include_context 'Get task status details', service_instance_location, "STAGE 4", [expected_output_1]
  end

  context "Get task status details for action executed on #{node_images[2]} node" do
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