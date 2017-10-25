# Test Case 01: Converge wordpress multi node scenario
# This test script will test following: 
# - converge multi node scenario
# - test passing links between components that exist on different nodes

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'wordpress_multi_node'
service_name = 'wordpress_multi_node'
remote_module = 'dtk-examples/wordpress'
remote_module_location = '/tmp/wordpress'
remote_module_version = '1.7.0'
service_location = '~/dtk/'

dtk_common = Common.new('', '')

describe "(Different node templates) Converge wordpress multi node scenario" do
  before(:all) do
    puts '*****************************************************************', ''
    # Install dtk-examples/wordpress module with required dependency modules
    system("mkdir #{remote_module_location}")
    system("dtk module install --update-deps -d #{remote_module_location} #{remote_module}")
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", remote_module, remote_module_location, assembly_name, service_name
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Delete service instance" do
    include_context "Delete service instance", service_location, service_name, dtk_common
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  context "Uninstall module" do
    include_context "Uninstall module", remote_module, remote_module_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", remote_module_location
  end

  after(:all) do
    puts '', ''
  end
end