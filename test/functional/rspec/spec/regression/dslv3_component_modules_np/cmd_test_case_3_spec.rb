# Test Case 3: Add new component from dtk.module.yaml file, push to server, stage assembly and check changes

require './lib/dtk_cli_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/dslv3_component_modules_np/resources/cmd_test_case_3"
module_location = '/tmp/cmd_test_case_3'
module_name = 'test/cmd_test_case_3'
assembly_name = 'test_assembly'
service_name = 'cmd_test_case_3'
service_location = "~/dtk/"
component_to_check_1 = "ec2::node[node]/cmd_test_case_3::first_component"
component_to_check_2 = "ec2::node[node]/cmd_test_case_3::second_component"
original_module_name = 'cmd_test_case_3_dtk.module.yaml'
delta_module_content = 'delta_cmd_test_case_3_dtk.module.yaml'

dtk_common = Common.new("", "")

describe '(Component Module DSL) Test Case 3: Add new component from dtk.module.yaml file, push to server, stage assembly and check changes' do
  before(:all) do
    puts '*********************************************************************************************************************************', ''
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

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check_1
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

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check_1
  end

  context "Check component exist in service instance" do
    include_context "Check component exist in service instance", dtk_common, service_name, component_to_check_2
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
