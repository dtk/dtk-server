# Test Case 18: Stage service and then try to delete component, delete node

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

deleted_component_assembly_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_18_1_dtk.service.yaml"
deleted_node_assembly_location = "./spec/regression/staging_and_deploying_services/resources/stda_test_case_18_2_dtk.service.yaml"

component_to_check = "node/test_delete::component"
node_to_check = "node"

module_name = 'r8/test_delete'
module_location = '/tmp/test_delete'
assembly_name = 'delete_workflow'
service_name = 'stda_test_case_18_instance'
service_location = "~/dtk/"
full_service_location = service_location + service_name
version = 'master'

dtk_common = Common.new('', '')

describe '(Staging And Deploying Assemblies) Test Case 18: Stage service and then try to delete component, delete node' do
  before(:all) do
    puts '************************************************************************************************************', ''
    # Install/clone r8:test_delete module with required dependency modules
    system("mkdir #{module_location}")
    system("dtk module clone -v #{version} #{module_name} #{module_location}")
    system("dtk module install -y -d #{module_location} #{module_name}")
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", module_name, module_location, assembly_name, service_name
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, deleted_component_assembly_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "NEG - Check component exist in service instance" do
    include_context "NEG - Check component exist in service instance", dtk_common, service_name, component_to_check
  end

  context "Check node exist in service instance" do
    include_context "Check node exist in service instance", dtk_common, service_name, node_to_check
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, deleted_node_assembly_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context "NEG - Check component exist in service instance" do
    include_context "NEG - Check component exist in service instance", dtk_common, service_name, component_to_check
  end

  context "NEG - Check node exist in service instance" do
    include_context "NEG - Check node exist in service instance", dtk_common, service_name, node_to_check
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  after(:all) do
    puts '', ''
  end
end