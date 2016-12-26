# Test Case 10: NEG - Have attribute with required field set to - falsee in dtk.model.yaml file, push to server

require './lib/dtk_cli_spec'
require './lib/dtk_common'

initial_module_location = "./spec/regression/dslv3_component_modules_np/resources/cmd_test_case_10"
module_location = '/tmp/cmd_test_case_10'
module_name = 'test/cmd_test_case_10'
assembly_name = 'test_assembly'
original_module_name = 'cmd_test_case_10_dtk.module.yaml'
delta_module_content = 'delta_cmd_test_case_10_dtk.module.yaml'
delta_2_module_content = 'delta_2_cmd_test_case_10_dtk.module.yaml'
delta_3_module_content = 'delta_3_cmd_test_case_10_dtk.module.yaml'
delta_4_module_content = 'delta_4_cmd_test_case_10_dtk.module.yaml'
delta_5_module_content = 'delta_5_cmd_test_case_10_dtk.module.yaml'
delta_6_module_content = 'delta_6_cmd_test_case_10_dtk.module.yaml'

dtk_common = Common.new("", "")

describe '(Component Module DSL) Test Case 10: NEG - Have attribute with required field set to - falsee in dtk.model.yaml file, push to server' do
  before(:all) do
    puts '************************************************************************************************************************************', ''
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

  context "Replace original content of dtk.module.yaml with delta content" do
    include_context "Replace original content of dtk.module.yaml with delta content", module_location, delta_module_content
  end

  context "NEG - Push module changes" do
    include_context "NEG - Push module changes", module_name, module_location
  end

  context "Replace original content of dtk.module.yaml with delta content" do
    include_context "Replace original content of dtk.module.yaml with delta content", module_location, delta_2_module_content
  end

  context "NEG - Push module changes" do
    include_context "NEG - Push module changes", module_name, module_location
  end

  context "Replace original content of dtk.module.yaml with delta content" do
    include_context "Replace original content of dtk.module.yaml with delta content", module_location, delta_3_module_content
  end

  context "NEG - Push module changes" do
    include_context "NEG - Push module changes", module_name, module_location
  end

  context "Replace original content of dtk.module.yaml with delta content" do
    include_context "Replace original content of dtk.module.yaml with delta content", module_location, delta_4_module_content
  end

  context "NEG - Push module changes" do
    include_context "NEG - Push module changes", module_name, module_location
  end

  context "Replace original content of dtk.module.yaml with delta content" do
    include_context "Replace original content of dtk.module.yaml with delta content", module_location, delta_5_module_content
  end

  context "NEG - Push module changes" do
    include_context "NEG - Push module changes", module_name, module_location
  end

  context "Replace original content of dtk.module.yaml with delta content" do
    include_context "Replace original content of dtk.module.yaml with delta content", module_location, delta_6_module_content
  end

  context "NEG - Push module changes" do
    include_context "NEG - Push module changes", module_name, module_location
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