require './lib/dtk_cli_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_01_dtk.module.yaml"
module_location = '/tmp/new_dtk_client_test_case_01'
module_name = 'test/new_dtk_client_test_case_01'
assembly_name = 'new_module_assembly'
service_name = 'new_dtk_client_test_case_01'
service_location = "~/dtk/"

dtk_common = Common.new('', '')

describe "(New DTK client) Test Case 1: Smoke test of new dtk client" do
  before(:all) do
    puts '**********************************************************', ''
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

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Destroy service instance" do
    include_context "Destroy service instance", service_location, service_name
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
