require './lib/dtk_cli_spec'
require './lib/dtk_common'

initial_master_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_02_1_dtk.module.yaml"
initial_version_module_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_02_2_dtk.module.yaml"
module_location = '/tmp/new_dtk_client_test_case_02'
module_name = 'test/new_dtk_client_test_case_02'
master_assembly_name = 'master_module_assembly'
version_assembly_name = 'version_module_assembly'

remote_module = 'test/new_client_module'
remote_master_module_assembly_name = 'master_module_assembly'
remote_version_module_assembly_name = 'version_module_assembly'
remote_module_version = '0.0.1'
remote_module_location = '/tmp/new_client_module'

dtk_common = Common.new('', '')

describe "(New DTK client) Test Case 2: Test various module installation options" do
  before(:all) do
    puts '**********************************************************************', ''
  end

  # Install master version of module from local filesystem
  context "Setup initial module on filesystem" do
    include_context "Setup initial module on filesystem", initial_master_module_location, module_location
  end

  context "Install module" do
    include_context "Install module", module_name, module_location
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", module_name, master_assembly_name, dtk_common
  end

  context "Uninstall module" do
    include_context "Uninstall module", module_name
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_location
  end

  # Install specific version of module from local filesystem
  context "Setup initial module on filesystem" do
    include_context "Setup initial module on filesystem", initial_version_module_location, module_location
  end

  context "Install module" do
    include_context "Install module", module_name, module_location
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", module_name, version_assembly_name, dtk_common
  end

  context "Uninstall module" do
    include_context "Uninstall module", module_name
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_location
  end

  # Install master version of module from remote
  context "Install module from dtkn" do
    include_context "Install module from dtkn", remote_module, remote_module_location, 'master'
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", remote_module, remote_master_module_assembly_name, dtk_common
  end

  context "Uninstall module" do
    include_context "Uninstall module", remote_module
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", remote_module_location
  end

  # Install specific version of module from remote
  context "Install module from dtkn" do
    include_context "Install module from dtkn", remote_module, remote_module_location, remote_module_version
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", remote_module, remote_version_module_assembly_name, dtk_common
  end

  context "Uninstall module" do
    include_context "Uninstall module", remote_module
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", remote_module_location
  end

  after(:all) do
    puts '', ''
  end
end