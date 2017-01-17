# Test Case 17: Converge service instance with component that has delete action and delete this component

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

deleted_component_assembly_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_17_dtk.service.yaml"

component_to_check = "node/test_delete::component"
node_to_check = "node"
error_message = "Service instance cannot be deleted because it is not empty"

module_name = 'r8/test_delete'
module_location = '/tmp/test_delete'
assembly_name = 'delete_workflow'
service_name = 'stda_test_case_17_instance'
service_location = "~/dtk/"
full_service_location = service_location + service_name
version = 'master'

dtk_common = Common.new('', '')

describe '(Staging And Deploying Assemblies) Test Case 17: Converge service instance with component that has delete action and delete this component' do
  before(:all) do
    puts '******************************************************************************************************************************************', ''
    # Install/clone r8:test_delete module with required dependency modules
    system("mkdir #{module_location}")
    system("dtk module clone -v #{version} #{module_name} #{module_location}")
    system("dtk module install -y -d #{module_location} #{module_name}")
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, deleted_component_assembly_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "NEG - Check component exist in service instance" do
    include_context "NEG - Check component exist in service instance", dtk_common, service_name, component_to_check
  end

  context "Check node exist in service instance" do
    include_context "Check node exist in service instance", dtk_common, service_name, node_to_check
  end

  context "NEG - Uninstall module" do
    include_context "NEG - Uninstall module", module_name, module_location, error_message
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