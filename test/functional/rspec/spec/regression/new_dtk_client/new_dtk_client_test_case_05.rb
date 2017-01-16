# This test script is used to test various options for service push
# Things that are under test are:
# - basic service push ability
# - ability to add non existing component with service push and handle error
# - ability to add new node and new component with service push
# - ability to add new node group and new component with service push
# - ability to delete added node/node group and new component with service push

require './lib/dtk_cli_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_05_1_dtk.module.yaml"
update_component_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_05_2_dtk.service.yaml"
update_node_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_05_3_dtk.service.yaml"
update_node_group_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_05_4_dtk.service.yaml"
revert_back_changes_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_05_5_dtk.service.yaml"

module_location = '/tmp/new_dtk_client_test_case_05'
module_name = 'test/new_dtk_client_test_case_05'
assembly_name = 'test_assembly'
service_name = 'new_dtk_client_test_case_05'
service_location = '~/dtk/'
full_service_location = service_location + service_name

non_existing_component = 'node/non_existing_component'
error_message = "Component '#{non_existing_component}' does not match any installed component templates"
node_to_check = 'new_node'
node_group_to_check = 'new_node_group'
cardinality = 2
component_to_check = 'new_node/stdlib'
component_to_check_on_node_group = 'new_node_group/stdlib'

dtk_common = Common.new('', '')

describe "(New DTK client) Test Case 5: Test various options for service push" do
  before(:all) do
    puts '*******************************************************************', ''
  end

  context "Setup initial module on filesystem" do
    include_context "Setup initial module on filesystem", initial_module_location, module_location
  end

  context "Install module" do
    include_context "Install module", module_name, module_location
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", module_name, assembly_name, dtk_common
  end

  context "Stage updated assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_component_service_location
  end

  context "NEG - Push service instance changes" do
    include_context "NEG - Push service instance changes", service_name, full_service_location
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_node_service_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Check node exist in service instance" do
    include_context "Check node exist in service instance", dtk_common, service_name, node_to_check
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_node_group_service_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check_on_node_group
  end

  context "Check node exist in service instance" do
    include_context "Check node exist in service instance", dtk_common, service_name, node_to_check
  end

  context "Check node group exist in service instance" do
    include_context "Check node group exist in service instance", dtk_common, service_name, node_group_to_check, cardinality
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, revert_back_changes_service_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "NEG - Check node exist in service instance" do
    include_context "NEG - Check node exist in service instance", dtk_common, service_name, node_to_check
  end

  context "NEG - Check node group exist in service instance" do
    include_context "NEG - Check node group exist in service instance", dtk_common, service_name, node_group_to_check, cardinality
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
    include_context "Uninstall module", module_name, module_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_location
  end

  after(:all) do
    puts '', ''
  end
end