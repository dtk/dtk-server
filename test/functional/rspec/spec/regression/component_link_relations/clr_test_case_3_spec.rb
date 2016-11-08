#!/usr/bin/env ruby
# Test Case 3: Fan-in scenario - $node.host_address from sink component are linked to upstream attributes of source components that exist on different nodes (source1, source2)

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

module_name = 'dtk18:unit_test'
module_location = '~/modules/dtk18/unit_test'
service_location = "~/dtk/"

service_name = 'clr_test_case_3_instance'
assembly_name = 'fan_in'
node_name_1 = 'source1'
node_name_2 = 'source2'
component_name = 'unit_test::source'
type = 'unit_test::sink'
dependency_component = 'sink/unit_test::sink'
attributes_to_check_1_1 = {"#{node_name_1}/upstream" => 'nil'}
attributes_to_check_1_2 = {"#{node_name_1}/upstream" => 'ec2'}
attributes_to_check_2_1 = {"#{node_name_2}/upstream" => 'nil'}
attributes_to_check_2_2 = {"#{node_name_2}/upstream" => 'ec2'}

dtk_common = Common.new(service_name, assembly_name)

describe '(Component link relations) Test Case 3: Fan-in scenario - $node.host_address from sink component are linked to upstream attributes of source components that exist on different nodes (source1, source2)' do
  before(:all) do
    puts '********************************************************************************************************************************************************************************************************', ''
    # Install/clone dtk18:unit_test module with required dependency modules
    system("dtk module clone #{module_name} #{module_location}")
    system("dtk module install -d #{module_location} #{module_name}")
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context 'List component dependencies' do
    include_context 'List component dependencies', service_name, "#{node_name_1}/#{component_name}", dependency_component, type
  end

  context 'List component dependencies' do
    include_context 'List component dependencies', service_name, "#{node_name_2}/#{component_name}", dependency_component, type
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_1_1
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_2_1
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_1_2
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_2_2
  end

  context "Destroy service instance" do
    include_context "Destroy service instance", service_location, service_name
  end

  after(:all) do
    puts '', ''
  end
end
