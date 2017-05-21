require './lib/dtk_cli_spec'
require './lib/dtk_common'

# Target specific properties
service_location = '~/dtk/'
target_location = "/tmp/network"
target_module = 'aws/network'
target_assembly_template = 'target_iam'
target_service_name = 'target_iam'
target_name = 'target_iam'
target_version = '1.0.4'

# Target attributes
default_keypair = 'testing_use1'

# Module specific properties
module_location = '/tmp/network'
module_name = 'aws/network'
service_name = 'target_iam'

dtk_common = Common.new('', '')

describe "Target setup and update" do
  before(:all) do
    puts '**********************************************', ''
    system("dtk service uninstall -y -r --delete -d #{service_location}/#{service_name}")
    system("rm -rf #{service_location}/#{service_name}")
    system("dtk module uninstall -v #{target_version} -y -d #{target_location} #{target_module}")
    system("rm -rf #{target_location}")
    system("mkdir #{target_location}")
    system("dtk module install --update-deps -d #{target_location} #{target_module}")
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", target_module, target_assembly_template, dtk_common
  end

  context "Stage target from module" do
    include_context "Stage target from module", target_module, target_location, target_name, target_service_name
  end

  context "Set attribute for default keypair" do
    include_context "Set attribute", service_location, target_service_name, 'network_aws::vpc[vpc1]/default_keypair', default_keypair
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, target_service_name
  end

  context "Set default target" do
    include_context "Set default target", target_service_name
  end

  after(:all) do
    puts '', ''
  end
end

