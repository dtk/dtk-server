#!/usr/bin/env ruby
# Test Case 7: Stage simple node group example, list nodes, delete nodes, check cardinality, list nodes/components/attributes after delete

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

initial_module_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_7_1_dtk.module.yaml"
updated_node_group_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_7_2_dtk.service.yaml"

module_name = 'newclient:node_group_test_07'
module_location = '~/modules/newclient/node_group_test_07'
service_location = "~/dtk/"
service_name = 'stda_test_case_7_instance'
assembly_name = 'simple'
component_to_check_1 = 'slave:1/stdlib'
component_to_check_2 = 'slave:2/stdlib'
node_group_to_check = 'slave'
full_service_location = service_location + service_name
expected_cardinality_before_delete = 2
expected_cardinality_after_delete = 1
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

  context "Check node group exist in service instance" do
    include_context "Check node group exist in service instance", dtk_common, service_name, node_group_to_check, expected_cardinality_before_delete
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check_1
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check_2
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, updated_node_group_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "Check node group exist in service instance" do
    include_context "Check node group exist in service instance", dtk_common, service_name, node_group_to_check, expected_cardinality_after_delete
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check_1
  end

  context "NEG - Check component exist in service instance" do
    include_context "NEG - Check component exist in service instance", dtk_common, service_name, component_to_check_2
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
