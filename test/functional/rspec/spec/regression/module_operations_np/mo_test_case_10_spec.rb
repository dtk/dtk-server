# Test Case 10: Import module from remote repo, check its corresponding assemblies, stage and check dependent modules
# Pre-requisite: r8/bakir_test_apache(master) exists on repo manager

require './lib/dtk_common'
require './lib/dtk_cli_spec'

module_name = 'r8/bakir_test_apache'
module_version = 'master'
module_location = '/tmp/r8/bakir_test_apache'
assembly_name = 'test_apache'
service_name = 'mo_test_case_10'
service_location = "~/dtk/"
module_to_check = 'apache'

dtk_common = Common.new('', '')

describe '(Module operations) Test Case 10: Import module from remote repo, check its corresponding assemblies, stage and check dependent modules' do
  before(:all) do
    puts '***************************************************************************************************************************************', ''
    system("mkdir -p #{module_location}")
  end

  context "Install module from dtkn" do
    include_context "Install module from dtkn", module_name, module_location, module_version
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", module_name, assembly_name, dtk_common
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Check dependency modules" do
    include_context "Check dependency module exists on service instance", dtk_common, service_name, service_location, module_to_check
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
