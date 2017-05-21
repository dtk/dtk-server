# Test Case 15: Converge service instance with component that has delete action and delete/uninstall service

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

component_to_delete = "node/test_delete::component"
node_to_delete = "node"

module_name = 'r8/test_delete'
module_location = '/tmp/test_delete'
assembly_name = 'delete_workflow'
service_name = 'stda_test_case_15_instance'
service_location = "~/dtk/"
version = 'master'

dtk_common = Common.new('', '')

describe '(Staging And Deploying Assemblies) Test Case 15: Converge service instance with component that has delete action and delete/uninstall service' do
  before(:all) do
    puts '*********************************************************************************************************************************************', ''
    # Install/clone r8:test_delete module with required dependency modules
    system("mkdir #{module_location}")
    system("dtk module clone -v #{version} #{module_name} #{module_location}")
    system("dtk module install --update-deps -d #{module_location} #{module_name}")
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
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

  context "NEG - Check component exist in service instance" do
    include_context "NEG - Check component exist in service instance", dtk_common, service_name, component_to_delete
  end

  context "NEG - Check node exist in service instance" do
    include_context "NEG - Check node exist in service instance", dtk_common, service_name, node_to_delete
  end

  after(:all) do
    puts '', ''
  end
end