# This test script is used to test various options for service push
# Things that are under test are:
# - basic service push ability
# - ability to change attributes with service push
# - ability to add new workflow with service push
# - ability to exec new workflow

require './lib/dtk_cli_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_04_1_dtk.module.yaml"
update_attribute_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_04_2_dtk.service.yaml"
update_workflow_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_04_3_dtk.service.yaml"

module_location = '/tmp/new_dtk_client_test_case_04'
module_name = 'test/new_dtk_client_test_case_04'
assembly_name = 'test_assembly'
service_name = 'new_dtk_client_test_case_04'
service_location = "~/dtk/"
full_service_location = service_location + service_name + "-" + test_assembly

attributes_to_check = {'node/image' => 'amazon_hvm', 'node/size' => 'small'}
component_to_check = "node/maven"
workflow_to_check = 'install_maven'

dtk_common = Common.new('', '')

describe "(New DTK client) Test Case 4: Test various options for service push" do
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
    include_context "Change content of service instance on local filesystem", full_service_location, update_attribute_service_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_workflow_service_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check
  end

  context "Check workflow exist in service instance" do
    include_context "Check workflow exist in service instance", dtk_common, service_name, workflow_to_check
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Exec action/workflow" do
    include_context "Exec action/workflow", dtk_common, service_location, service_name, workflow_to_check
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