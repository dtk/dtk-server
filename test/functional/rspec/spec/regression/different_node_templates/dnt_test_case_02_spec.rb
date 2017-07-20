# Test Case 02: Converge rails local app with datadog integration
# This test script will test following: 
# - converge rails local app on nginx with postgres 
# - establish integration with datadog in order to show postgres and rails metrics on datadog dashboards
# - execute ruby provider actions for creating screenboard/timeboard on datadog and attaching metrics to it

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'rails_app_local'
service_name = 'rails_local_app_with_datadog'
remote_module = 'dtk-examples/rails'
remote_module_location = '/tmp/rails'
remote_module_version = 'master'
service_location = '~/dtk/'
api_key = 'ccb08354705864db6041d30fc4621529'
app_key = 'af01ce7a8180b837f53b01f914ea7f0f82f4d6ba'

dtk_common = Common.new('', '')

describe "(Different node templates) Converge rails local app with datadog integration" do
  before(:all) do
    puts '****************************************************************************', ''
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

  context "Set attribute for datadog api key" do
    include_context "Set attribute", service_location, service_name, 'node/datadog_api::smoke_test/api_key', api_key
  end

  context "Set attribute for datadog app key" do
    include_context "Set attribute", service_location, service_name, 'node/datadog_api::smoke_test/application_key', app_key
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