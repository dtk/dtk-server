# Test Case 4: Service with node (node groups = 2) that contains cmp with bash and rspec actions
# This test script will test following: 
# - converge service instance with action module component
# - execute actions (bash and rspec) on multiple nodes that are part of node group

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'node-group'
service_name = 'af_test_case_4_instance'
module_location = '/tmp/action_module'
module_name = 'r8/action_module'
module_version = 'master'
service_location = '~/dtk/'

dtk_common = Common.new(service_name, assembly_name)

expected_output_1 = {
  command: '/bin/sh /etc/puppet/modules/action_module/bash_tests/test_bash.sh',
  status: 'succeeded',
  return_code: 0
}

expected_output_2 = {
  command: '/opt/puppet-omnibus/embedded/bin/rspec /etc/puppet/modules/action_module/rspec_tests/spec/test_spec.rb',
  status: 'succeeded',
  return_code: 0
}

describe '(Action Framework) Test Case 4: Service with node (node groups = 2) that contains cmp with bash and rspec actions' do
  before(:all) do
    puts '*****************************************************************************************************************', ''
    # Install/clone r8:action_module module with required dependency modules if needed
    location_exist = `ls #{module_location}"`
    unless location_exist.include? "No such file or directory"
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

  context 'Get task status details for action with bash script command' do
    include_context 'Get task status details', dtk_common, "STAGE 3", [expected_output_1]
  end

  context 'Get task status details for action with bash script command' do
    include_context 'Get task status details', dtk_common, "STAGE 3", [expected_output_1]
  end

  context 'Get task status details for action with rspec test command' do
    include_context 'Get task status details', dtk_common, "STAGE 4", [expected_output_2]
  end

  context 'Get task status details for action with rspec test command' do
    include_context 'Get task status details', dtk_common, "STAGE 4", [expected_output_2]
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
