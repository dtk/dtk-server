# Test Case 9: Import module from remote repo and check its corresponding assemblies
# Pre-requisite: r8/bakir_test_apache(master) exists on repo manager

require './lib/dtk_common'
require './lib/dtk_cli_spec'

module_name = 'r8/bakir_test_apache'
module_version = 'master'
module_location = '/tmp/r8/bakir_test_apache'
assembly_name = 'test_apache'

dtk_common = Common.new('', '')

describe '(Module operations) Test Case 9: Import module from remote repo and check its corresponding assemblies' do
  before(:all) do
    puts '******************************************************************************************************', ''
    system("mkdir -p #{module_location}")
  end

  context "Install module from dtkn" do
    include_context "Install module from dtkn", module_name, module_location, module_version
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", module_name, assembly_name, dtk_common
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
