# Test Case 12: Ability to add and delete components on assembly level and set their attributes

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

initial_module_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_12_1_dtk.module.yaml"
updated_components_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_12_2_dtk.service.yaml"
deleted_components_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_12_3_dtk.service.yaml"

module_name = 'newclient:stda_test_case_12'
module_location = '~/modules/newclient/stda_test_case_12'
service_location = "~/dtk/"
service_name = 'stda_test_case_12'
assembly_name = 'simple'
node_name = 'single_node'
component_name = 'puppetlabs:wget'
component_to_check_1 = 'wget'
component_to_check_2 = "ec2::node[single_node]/wget"
attributes_to_check = {'wget/version' => '1.0.0', 'single_node/wget/version' => '1.0.0' }
full_service_location = service_location + service_name
dtk_common = Common.new('', '')

describe '(Staging And Deploying Assemblies) Test Case 12: Ability to add and delete components on assembly level and set their attributes' do
  before(:all) do
    puts '********************************************************************************************************************************', ''
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

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context 'List service instances after stage' do
    include_context 'List service instances after stage', dtk_common, service_name
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, updated_components_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check_1
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check_2
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, deleted_components_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "NEG - Check component exist in service instance" do
    include_context "NEG - Check component exist in service instance", dtk_common, service_name, component_to_check_1
  end

  context "NEG - Check component exist in service instance" do
    include_context "NEG - Check component exist in service instance", dtk_common, service_name, component_to_check_2
  end

  context "NEG - Check attributes correct in service instance" do
    include_context "NEG - Check attributes correct in service instance", dtk_common, service_name, attributes_to_check
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
