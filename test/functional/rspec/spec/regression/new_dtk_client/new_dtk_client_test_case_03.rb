# This test script is used to test various options for module push
# Things that are under test are:
# - basic module push ability
# - ability to add new component with module push
# - ability to remove added component with module push

require './lib/dtk_cli_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_03_1_dtk.module.yaml"
updated_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_03_2_dtk.module.yaml"
module_location = '/tmp/new_dtk_client_test_case_03'
module_name = 'test/new_dtk_client_test_case_03'
assembly_name = 'test_assembly'
service_name = 'new_dtk_client_test_case_03'
service_location = "~/dtk/"
component_to_check = "node/mysql::server"

dtk_common = Common.new('', '')

describe "(New DTK client) Test Case 3: Test various options for module push" do
  before(:all) do
    puts '******************************************************************', ''
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

  context "Delete module on filesystem" do
    include_context "Delete initial module on filesystem", module_location
  end

  context "Clone module on filesystem" do
    include_context "Clone module on filesystem", module_name, module_location
  end

  context "Change content of module on local filesystem" do
    include_context "Change content of module on local filesystem", module_location, updated_module_location
  end

  context "Push module changes" do
    include_context "Push module changes", module_name, module_location
  end

  context "Stage updated assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  context "Change content of module on local filesystem" do
    include_context "Change content of module on local filesystem", module_location, initial_module_location
  end

  context "Push module changes" do
    include_context "Push module changes", module_name, module_location
  end

  context "Stage restored assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "NEG - Check component exist in service instance" do
    include_context "NEG - Check component exist in service instance", dtk_common, service_name, component_to_check
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