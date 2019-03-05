# Test Case 1: Stage existing assembly and then delete service

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

module_name = 'newclient:bootstrap'
module_location = '~/modules/newclient/bootstrap'
service_location = "~/dtk/"
service_name = 'stda_test_case_1_instance'
assembly_name = 'node_with_params'
dtk_common = Common.new('', '')

describe '(Staging And Deploying Assemblies) Test Case 1: Stage existing assembly and then delete service' do
  before(:all) do
    puts '************************************************************************************************', ''
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context 'List service instances after stage' do
    include_context 'List service instances after stage', dtk_common, service_name
  end

  context "Delete service instance" do
    include_context "Delete service instance", service_location, service_name, dtk_common
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  context 'List service instances after delete' do
    include_context 'List service instances after delete', dtk_common, service_name
  end

  after(:all) do
    puts '', ''
  end
end