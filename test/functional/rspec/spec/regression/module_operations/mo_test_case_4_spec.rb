# Test Case 4: Install module (service part) from one namespace, create with another namespace, publish module version and delete from remote
# Pre-requisite: r8/new_test_service_module(master) exists on repo manager

require './lib/dtk_common'
require './lib/dtk_cli_spec'

module_1 = 'r8/new_test_service_module'
module_1_version = 'master'
module_1_location = '/tmp/r8/new_test_service_module'

module_2 = 'test_ns/new_test_service_module'
module_2_version = '0.0.1'
module_2_location = '/tmp/test_ns/new_test_service_module'

dtk_common = Common.new('', '')

describe '(Module operations) Test Case 4: Install module (service part) from one namespace, create with another namespace, publish module version and delete from remote' do
  before(:all) do
    puts '***************************************************************************************************************************************************************', ''
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
      `sed -i "s#version: #{module_1_version}#version: #{module_2_version}#g" #{module_2_location}/dtk.module.yaml`
      value = `cat #{module_2_location}/dtk.module.yaml | grep #{module_2}`
      pass = !value.include?('No such file or directory')
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