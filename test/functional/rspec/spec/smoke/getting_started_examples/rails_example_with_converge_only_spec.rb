# This test script is used to test deployment of getting started example: dtk-examples/rails
# Things that are under test are:
# - ability to stage and converge rails example and have rails application with postgres/nginx up and running

require './lib/dtk_cli_spec'
require './lib/dtk_common'

assembly_name = 'rails_single_node'
service_name = "rails_single_node_getting_started" + rand(10..1000).to_s
remote_module = 'dtk-examples/rails'
remote_module_location = '/tmp/rails'
service_location = '~/dtk/'

dtk_common = Common.new('', '')

describe "Getting started example: dtk-examples/rails" do
  before(:all) do
    puts '*******************************************', ''
    system("mkdir #{remote_module_location}")
    system("dtk module install --update-deps -d #{remote_module_location} #{remote_module}")
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", remote_module, assembly_name, dtk_common
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", remote_module, remote_module_location, assembly_name, service_name
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Uninstall service instance with --force" do
    include_context "Uninstall service instance with --force", service_location, service_name
  end

  after(:all) do
    system("rm -rf #{remote_module_location}")
    puts '', ''
  end
end