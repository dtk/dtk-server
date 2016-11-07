#!/usr/bin/env ruby
# Test Case 1: Simple link scenario - $node.host_address from sink component is passed to upstream attribute of source component

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

STDOUT.sync = true

module_name = 'dtk18:unit_test'
module_location = '~/modules/unit_test'
service_location = "~/dtk/"

service_name = 'clr_test_case_1_instance'
assembly_name = 'unit_test::simple_link'
node_name = 'source'
component_name = 'unit_test::source'
namespace = 'dtk18'
type = 'unit_test::sink'
dependency_component = 'sink/unit_test::sink'
attributes_to_check_1 = {"#{node_name}/upstream" => 'nil'}
attributes_to_check_2 = {"#{node_name}/upstream" => 'ec2'}

dtk_common = Common.new('', '')

describe '(Component link relations) Test Case 1: Simple link scenario - $node.host_address from sink component is passed to upstream attribute of source component' do
  before(:all) do
    puts '*********************************************************************************************************************************************************', ''
    # Install/clone dtk18:unit_test module with required dependency modules
    system("dtk module clone #{module_name} #{module_location}")
    system("dtk module install -d #{module_location} #{module_name}")
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context 'List component dependencies' do
    include_context 'List component dependencies', service_name, "#{node_name}/#{component_name}", dependency_component, type
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_1
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_2
  end

  context "Destroy service instance" do
    include_context "Destroy service instance", service_location, service_name
  end

  after(:all) do
    puts '', ''
  end
end
