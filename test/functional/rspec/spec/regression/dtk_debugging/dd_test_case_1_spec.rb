# Test Case 1: This test script is used to test breakpoint feature on both create and delete (assembly wide)
# Things that are under test are:
# - ability to stop on specific breakpoint in create phase on assembly wide component
# - ability to stop on specific breakpoint in delete phase on assembly wide component

require './lib/dtk_cli_spec'
require './lib/dtk_common'

module_location = "./spec/regression/dtk_debugging/resources"
module_name = 'test/ruby_provider_test_module'
assembly_name = 'assembly_wide_single_debug'
service_name = 'assembly_wide_single_debug'
service_location = "~/dtk/"

create_subtask_names_with_breakpoint = ['create first test component']
delete_subtask_names_with_breakpoint = ['2.1.1 configure_nodes']

dtk_common = Common.new('', '')

describe "(DTK debugging) Test Case 1: Converge instance with one breakpoint on both create and delete (assembly wide)" do
  before(:all) do
    puts '************************************************************************************************************', ''
    system("dtk module install --update-deps -d #{module_location}")
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", module_name, assembly_name, dtk_common
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Converge service instance with breakpoint" do
    include_context "Converge service instance with breakpoint", service_location, dtk_common, service_name, create_subtask_names_with_breakpoint
  end

  context "Delete service instance with breakpoint" do
    include_context "Delete service instance with breakpoint", service_location, dtk_common, service_name, delete_subtask_names_with_breakpoint
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  after(:all) do
    puts '', ''
  end
end