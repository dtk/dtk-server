# Test Case 9: Test adding verious default values for different attribute types

require './lib/dtk_cli_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/dslv3_component_modules_np/resources/cmd_test_case_9"
module_location = '/tmp/cmd_test_case_9'
module_name = 'test/cmd_test_case_9'
assembly_name = 'test_assembly'
service_name = 'cmd_test_case_9'
service_location = "~/dtk/"
original_module_name = 'cmd_test_case_9_dtk.module.yaml'
delta_module_content = 'delta_cmd_test_case_9_dtk.module.yaml'

attributes_to_check_1 = {
  'node/cmd_test_case_9::first_component/hash_attr'    => "",
  'node/cmd_test_case_9::first_component/hash_attr_2'  => "",
  'node/cmd_test_case_9::first_component/hash_attr_3'  => "",
  'node/cmd_test_case_9::first_component/hash_attr_4'  => "",
  'node/cmd_test_case_9::first_component/hash_attr_5'  => "",
}

attributes_to_check_2 = {
  'node/cmd_test_case_9::first_component/hash_attr'    => "{key1=>value1}",
  'node/cmd_test_case_9::first_component/hash_attr_2'  => "",
  'node/cmd_test_case_9::first_component/hash_attr_3'  => "{key1=>nil}",
  'node/cmd_test_case_9::first_component/hash_attr_4'  => "{key1=>[element1, element2]}",
  'node/cmd_test_case_9::first_component/hash_attr_5'  => "{key1=>value1, key2=>value2}",
}

dtk_common = Common.new("", "")

describe '(Component Module DSL) Test Case 9: Test adding verious default values for different attribute types' do
  before(:all) do
    puts '****************************************************************************************************', ''
  end

  context "Add original content of dtk.module.yaml and module content" do
    include_context "Add original content of dtk.module.yaml and module content", initial_module_location, module_location, original_module_name
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

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_1
  end

  context "Delete service instance" do
    include_context "Delete service instance", service_location, service_name, dtk_common
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  context "Replace original content of dtk.module.yaml with delta content" do
    include_context "Replace original content of dtk.module.yaml with delta content", module_location, delta_module_content
  end

  context "Push module changes" do
    include_context "Push module changes", module_name, module_location
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Check attributes correct in service instance" do
    include_context "Check attributes correct in service instance", dtk_common, service_name, attributes_to_check_2
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