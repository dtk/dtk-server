#!/usr/bin/env ruby
# Test Case 10: Install module from one namespace, create with another namespace, publish and delete from remote

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

module_1 = 'r8/jmeter'
module_1_version = 'master'
module_1_location = '/tmp/r8/jmeter'

module_2 = 'dtk17/jmeter'
module_2_version = 'master'
module_2_location = '/tmp/dtk17/jmeter'

dtk_common = Common.new('', '')

describe "(Modules, Services and Versioning) Test Case 10: Install module from one namespace, create with another namespace, publish and delete from remote" do
  before(:all) do
    puts '*************************************************************************************************************************************************', ''
    system("mkdir -p /tmp/r8/jmeter")
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
      value = `ls #{module_2_location}/manifests`
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
      value = `ls #{module_2}`
      pass = !value.include?('No such file or directory')
      puts ''
      pass.should eq(true)
    end
  end

  context "Install module from dtkn" do
    include_context "Install module from dtkn", module_2, module_2_location, module_2_version
  end

  context "Uninstall module" do
    include_context "Uninstall module", module_1, module_1_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_1_location
  end

  context "Delete module from remote" do
    include_context "Delete module from remote", dtk_common, module_2, module_2_location
  end

  after(:all) do
    system("rm -r /tmp/r8/jmeter")
    system("rm -r /tmp/dtk17/jmeter")
    puts '', ''
  end
end
