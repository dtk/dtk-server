require './lib/dtk_cli_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/dtk_cli/resources/dtk_cli_test_case_01_dtk.module.yaml"
module_location = '/tmp/dtk_cli_test_case_01'
module_name = 'test/dtk_cli_test_case_01'
assembly_name = 'new_module_assembly'
service_name = 'dtk_cli_test_case_01'
service_location = `~/dtk/#{service_name}`

dtk_common = Common.new('', '')

describe "(DTK CLI) Test Case 1: Smoke test of dtk cli" do
  before(:all) do
    puts '********************************************', ''
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

  context "Stage assembly from module"
    include_context "Stage assembly from module", module_name, assembly_name, service_name
  end

  context "Converge service instance"
    include_context "Converge service instance", service_location
  end

  context "Destroy service instance " do
    include_context "Destroy service instance", service_location
  end

  context "Uninstall module" do
    include_context "Uninstall module", module_name
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_location
  end

  after(:all) do
    puts '', ''
  end
end
