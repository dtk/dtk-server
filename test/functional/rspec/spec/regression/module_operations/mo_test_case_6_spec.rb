# Test Case 6: Install module (service and component part) from one namespace, create with another namespace, publish module version and delete from remote
# Pre-requisite: r8/unit_test(master) exists on repo manager

require './lib/dtk_common'
require './lib/dtk_cli_spec'

module_1 = 'r8/unit_test'
module_1_version = 'master'
module_1_location = '/tmp/r8/unit_test'

module_2 = 'test_ns/unit_test'
module_2_version = '0.0.1'
module_2_location = '/tmp/test_ns/unit_test'

dtk_common = Common.new('', '')

describe "(Module operations) Test Case 6: Install module (service and component part) from one namespace, create with another namespace, publish module version and delete from remote" do
  before(:all) do
    puts '*****************************************************************************************************************************************************************************', ''
    system("mkdir -p #{module_1_location}")
  end

  context "Install module from dtkn" do
    include_context "Install module from dtkn", module_1, module_1_location, module_1_version
  end

  context "Create new directory called #{module_2_location} and copy the content of #{module_1_location} in it" do
    it 'creates new directory with existing component module content in it' do
      puts 'Create new directory and copy the content of existing component module', '----------------------------------------------------------------------'
      pass = false
      `mkdir -p #{module_2_location}`
      `cp -r #{module_1_location}/* #{module_2_location}/`
      `sed -i "s#module: #{module_1}#module: #{module_2}#g" #{module_2_location}/dtk.module.yaml`
      value = `cat #{module_2_location}/dtk.module.yaml | grep #{module_2}`
      pass = value.include?('module: #{module_2}')
      puts ''
      pass.should eq(true)
    end
  end

  context "Install new module" do
    include_context "Install module", module_2, module_2_location
  end

  context "Publish module" do
    include_context "Publish module", module_2, module_2_location
  end

  context "Uninstall module" do
    include_context "Uninstall module", module_1, module_1_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_1_location
  end

  context "Uninstall module" do
    include_context "Uninstall module", module_2, module_2_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_2_location
  end

  context "Create new directory called #{module_2_location}" do
    it 'creates new directory' do
      puts 'Create new directory', '---------------------------'
      pass = false
      `mkdir -p #{module_2_location}`
      value = `ls #{module_2_location}`
      pass = !value.include?('No such file or directory')
      puts ''
      pass.should eq(true)
    end
  end

  context "Install module from dtkn" do
    include_context "Install module from dtkn", module_2, module_2_location, module_2_version
  end

  context "Check module has both service and component part" do
    it "checks that module has both service and component part" do
      puts "Check module has both service and component part", "---------------------------------------------"
      pass = false
      value_1 = `cat #{module_2_location}/dtk.module.yaml | grep component_defs`
      value_2 = `cat #{module_2_location}/dtk.module.yaml | grep assemblies`
      pass = (value_1.include?('component_defs')) && (value_2.include?('assemblies'))
      puts ''
      pass.should eq(true)
    end
  end

  context "Uninstall module" do
    include_context "Uninstall module", module_2, module_2_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_2_location
  end

  context "Delete module from remote" do
    include_context "Delete module from remote", dtk_common, module_2, module_2_version
  end

  after(:all) do
    system("rm -r #{module_1_location}")
    system("rm -r #{module_2_location}")
    puts '', ''
  end
end