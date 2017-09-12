# Test Case 02: Converge rails local app
# This test script will test following: 
# - converge rails local app on nginx with postgres

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'rails_single_node'
service_name = 'rails_single_node'
remote_module = 'dtk-examples/rails'
remote_module_location = '/tmp/rails'
remote_module_version = '1.0.0'
service_location = '~/dtk/'

dtk_common = Common.new('', '')

describe "(Different node templates) Converge rails local app" do
  before(:all) do
    puts '***************************************************', ''
  end

  context "Install module from dtkn" do
    include_context "Install module from dtkn", remote_module, remote_module_location, remote_module_version
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", remote_module, assembly_name, dtk_common
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", remote_module, remote_module_location, assembly_name, service_name
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

  context "Uninstall module" do
    include_context "Uninstall module", remote_module, remote_module_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", remote_module_location
  end

  after(:all) do
    puts '', ''
  end
end