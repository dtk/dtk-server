# This test script is used to test various options for delete and uninstall of service instance
# Things that are under test are:
# - stage assembly template, delete and uninstall
# - stage assembly template, converge, delete and uninstall
# - stage assembly template uninstall --delete
# - neg - stage assembly template, uninstall
# - stage assembly template, make local change and do delete with -f flag
# - neg - stage assembly template, make local change and do delete

require './lib/dtk_cli_spec'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_08_dtk.module.yaml"
update_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_08_dtk.service.yaml"
module_name = 'test/new_dtk_client_test_case_08'
module_location = '/tmp/new_dtk_client_test_case_08'
assembly_name = 'test_assembly'
service_name = 'new_dtk_client_test_case_08'
service_location = '~/dtk/'
full_service_location = service_location + service_name

delete_error_message = ''
uninstall_error_message = ''

dtk_common = Common.new('', '')

describe "(New DTK client) Test Case 8: Test various options for delete and uninstall of service instance" do
  before(:all) do
    puts '***********************************************************************************************', ''
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

  # 1: stage assembly template, delete and uninstall
  context "Stage updated assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Delete service instance" do
    include_context "Delete service instance", service_location, service_name, dtk_common
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  # 2: stage assembly template, converge, delete and uninstall
  context "Stage updated assembly from module" do
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

  # 3: stage assembly template uninstall --delete
  context "Stage updated assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  # 4: neg - stage assembly template, uninstall
  context "Stage updated assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "NEG - Uninstall service instance" do
    include_context "NEG - Uninstall service instance", service_location, service_name, uninstall_error_message
  end

  context "Delete service instance" do
    include_context "Delete service instance", service_location, service_name, dtk_common
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  # 5: stage assembly template, make local change and do delete with -f flag
  context "Stage updated assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_service_location
  end

  context "Force delete service instance" do
    include_context "Force delete service instance", service_location, service_name, dtk_common
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  # 6: neg - stage assembly template, make local change and do delete
  context "Stage updated assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_service_location
  end

  context "NEG - Delete service instance" do
    include_context "NEG - Delete service instance", service_location, service_name, dtk_common, delete_error_message
  end

  # cleanup
  context "Force delete service instance" do
    include_context "Force delete service instance", service_location, service_name, dtk_common
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