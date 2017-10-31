# This test script is used to test multiple breakpoints feature on both create and delete (node)
# Things that are under test are:
# - ability to stop on multiple breakpoints in create phase on components on the node
# - ability to stop on multiple breakpoints in delete phase on components on the node

require './lib/dtk_cli_spec'
require './lib/dtk_common'

module_location = "./spec/regression/dtk_debugging/resources"
module_name = 'test/debugger'
assembly_name = 'node_multiple_debug'
service_name = 'node_multiple_debug'
service_location = "~/dtk/"

create_subtask_names_with_breakpoint = ['create first test component', 'create second test component']
delete_subtask_names_with_breakpoint = ['delete first test component', 'delete second test component']

dtk_common = Common.new('', '')

describe "(DTK debugging) Test Case 4: Converge instance with two breakpoints on both create and delete (node)" do
  before(:all) do
    puts '*************************************', ''
    system("dtk module install --update-deps -d #{module_location}")
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", module_name, assembly_name, dtk_common
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Converge service instance with breakpoint" do
    include_context "Converge service instance with breakpoint", service_location, dtk_common, service_name, subtask_names_with_breakpoint
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