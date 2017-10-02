# Test Case 16: Converge service instance with component that has delete action add new node then delete node with delete action
# This test script will do following: 
# - converge new service instance
# - add new node in dtk.service.yaml of service instance and push changes
# - converge again
# - remove added node from dtk.service.yaml and push changes
# - converge again and check that delete action has been triggered on node that is being deleted

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

added_node_assembly_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_16_1_dtk.service.yaml"
deleted_node_assembly_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_16_2_dtk.service.yaml"

component_to_check = "second_node/test_delete::component"
node_to_check = "second_node"
error_message = "Service instance cannot be deleted because it is not empty"

module_name = 'r8/test_delete'
module_location = '/tmp/test_delete'
assembly_name = 'delete_workflow'
service_name = 'stda_test_case_16_instance'
service_location = "~/dtk/"
full_service_location = service_location + service_name
version = 'master'

dtk_common = Common.new('', '')

describe '(Staging And Deploying Assemblies) Test Case 16: Converge service instance with component that has delete action add new node then delete node with delete action' do
  before(:all) do
    puts '*****************************************************************************************************************************************************************', ''
    # Install r8:test_delete module with required dependency modules
    system("mkdir #{module_location}")
    system("dtk module install --update-deps -d #{module_location} #{module_name}")
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, added_node_assembly_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check
  end

  context "Check node exist in service instance" do
    include_context "Check node exist in service instance", dtk_common, service_name, node_to_check
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, deleted_node_assembly_location
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

  context "NEG - Check node exist in service instance" do
    include_context "NEG - Check node exist in service instance", dtk_common, service_name, node_to_check
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