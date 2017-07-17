require './lib/dtk_cli_spec'
require './lib/dtk_common'

# context specific properties
service_location = '~/dtk/'
context_location = "/tmp/network"
context_module = 'aws/aws_target'
context_assembly_template = 'target_iam'
context_service_name = 'context_iam'
context_name = 'target_iam'
context_version = 'master'

# context attributes
default_keypair = 'testing_use1'

# Module specific properties
module_location = '/tmp/network'
module_name = 'aws/aws_target'
service_name = 'context_iam'

dtk_common = Common.new('', '')

describe "context setup and update" do
  before(:all) do
    puts '**********************************************', ''
    system("dtk service uninstall -y -r --force -d #{service_location}/#{service_name}")
    system("rm -rf #{service_location}/#{service_name}")
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
    include_context "Set attribute", service_location, context_service_name, 'network_aws::vpc[vpc1]/default_keypair', default_keypair
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

