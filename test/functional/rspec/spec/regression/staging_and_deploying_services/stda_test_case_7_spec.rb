# Test Case 7: Stage simple node group example, list nodes, delete nodes, check cardinality, list nodes/components/attributes after delete

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

initial_module_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_7_1_dtk.module.yaml"
updated_node_group_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_7_2_dtk.service.yaml"

module_name = 'newclient:stda_test_case_7'
module_location = '~/modules/newclient/stda_test_case_7'
service_location = "~/dtk/"
service_name = 'stda_test_case_7'
assembly_name = 'simple'
attributes_to_check_cardinality_before = {"ec2::node_group[slave]/cardinality" => '2'}
attributes_to_check_cardinality_after = {"ec2::node_group[slave]/cardinality" => '1'}
node_group_to_check = "ec2::node_group[slave]"
full_service_location = service_location + service_name
dtk_common = Common.new('', '')

describe '(Staging And Deploying Assemblies) Test Case 7: Stage simple node group example, list nodes, delete node group member, check cardinality, list nodes/components/attributes after delete' do
  before(:all) do
    puts '***************************************************************************************************************************************************************************************', ''
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

  context "Check node group component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, node_group_to_check
  end

  context "Check cardinality attribute correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_cardinality_before
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, updated_node_group_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Check node group component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, node_group_to_check
  end

  context "Check cardinality attribute correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_cardinality_after
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
