require './lib/dtk_cli_spec'
require './lib/dtk_common'

# context specific properties
service_location = '~/dtk/'
context_location = "/tmp/network"
context_module = 'aws/aws_vpc'
context_assembly_template = 'discover_using_node_profile'
context_service_name = 'context_iam'
context_name = 'discover_using_node_profile'
context_version = '0.9.5'

# context attributes
default_keypair = 'testing_use1'

dtk_common = Common.new('', '')

describe "Context setup and update" do
  before(:all) do
    puts '**********************************************', ''
    system("dtk service uninstall -y -r --force -d #{service_location}/#{context_service_name}")
    system("rm -rf #{service_location}/#{context_service_name}")
    system("dtk module uninstall -v #{context_version} -y -d #{context_location} #{context_module}")
    system("rm -rf #{context_location}")
    system("mkdir #{context_location}")
    system("dtk module install --update-deps -d #{context_location} #{context_module}")
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", context_module, context_assembly_template, dtk_common
  end

  context "Stage context from module" do
    include_context "Stage context from module", context_module, context_location, context_name, context_service_name
  end

  context "Set attribute for default keypair" do
    include_context "Set attribute", service_location, context_service_name, 'ec2::profile[default]/key_name', default_keypair
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, context_service_name
  end

  context "Set default context" do
    include_context "Set default context", context_service_name
  end

  after(:all) do
    puts '', ''
  end
end

