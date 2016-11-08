#!/usr/bin/env ruby
# Test Case 2: Fan-out scenario - $node.host_address from sink components on different nodes (sink1, sink2) are linked to upstream attribute of source component

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

module_name = 'dtk18:unit_test'
module_location = '~/modules/dtk18/unit_test'
service_location = "~/dtk/"

service_name = 'clr_test_case_2_instance'
assembly_name = 'fan_out'
node_name = 'source'
component_name = 'unit_test::source'
type = 'unit_test::sink'
dependency_component_1 = 'sink1/unit_test::sink'
dependency_component_2 = 'sink2/unit_test::sink'
attributes_to_check = {"#{node_name}/upstream" => [nil, nil]}

dtk_common = Common.new('', '')

describe '(Component link relations) Test Case 2: Fan-out scenario - $node.host_address from sink components on different nodes (sink1, sink2) are linked to upstream attribute of source component' do
  before(:all) do
    puts '*****************************************************************************************************************************************************************************************', ''
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context 'List component dependencies' do
    include_context 'List component dependencies', dtk_common, service_name, "#{node_name}/#{component_name}", dependency_component_1, type
  end

  context 'List component dependencies' do
    include_context 'List component dependencies', dtk_common, service_name, "#{node_name}/#{component_name}", dependency_component_2, type
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "NEG - Check attributes correct in service instance" do
    include_context "NEG - Check attributes correct in service instance", dtk_common, service_name, attributes_to_check
  end

  context "Destroy service instance" do
    include_context "Destroy service instance", service_location, service_name
  end

  after(:all) do
    puts '', ''
  end
end
