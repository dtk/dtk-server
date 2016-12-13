# This test script is used to test various options for editing dependency module and service push
# Things that are under test are:
# - edit value for existing attribute in dtk.nested_module.yaml
# - add new attribute in dtk.nested_module.yaml
# - remove existing attribute from dtk.nested_module.yaml

require './lib/dtk_cli_spec'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_07_dtk.module.yaml"
dependency_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_07_1_dtk.nested_module.yaml"
module_name = 'test/new_dtk_client_test_case_07'
module_location = '/tmp/new_dtk_client_test_case_07'
assembly_name = 'test_assembly'
service_name = 'new_dtk_client_test_case_07'
service_location = '~/dtk/'
full_service_location = service_location + service_name
full_dependency_module_location = service_location + service_name + "/modules/mysql"
attributes_to_check = {'node/mysql::server/new_attribute' => 'new_attribute_value', 'node/mysql::server/remote_access' => 'true'}
missing_attributes_to_check = {'node/mysql::server/root_password' => ''}

dtk_common = Common.new('', '')

describe "(New DTK client) Test Case 7: Test various options for adding/removing/editing dependency module and service push" do
  before(:all) do
    puts '*****************************************************************************************************************', ''
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

  context "Change content of dependency module in service instance on local filesystem" do
    include_context "Change content of dependency module in service instance on local filesystem", full_dependency_module_location, dependency_module_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check
  end

  context "NEG - Check attributes correct in service instance" do
    include_context "NEG - Check attributes correct in service instance", dtk_common, service_name, missing_attributes_to_check
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