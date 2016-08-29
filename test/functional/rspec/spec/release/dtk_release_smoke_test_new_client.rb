require './lib/dtk_cli_spec'
require './lib/dtk_common'
require './lib/component_modules_spec'

initial_module_location = "./spec/smoke/resources/new_client_dtk.module.yaml"
module_location = '/tmp/dtk_new_client_smoke'
module_name = 'test/dtk_new_client_smoke'
assembly_name = 'new_module_assembly'
service_name = 'dtk_new_client_smoke'
service_location = "~/dtk/"

puppet_forge_module_name = 'puppetlabs-stdlib'
component_module_name = 'puppetlabs:stdlib'
component_module_filesystem_location = '~/dtk/component_modules/puppetlabs'
namespace = 'puppetlabs'

dtk_common = Common.new('', '')

describe "DTK Server release smoke test with new client" do
  before(:all) do
    puts '*********************************************', ''
  end

  # import module from puppet forge needed for module in new client as dependency
  context 'Import module from puppet forge' do
    include_context 'Import module from puppet forge', puppet_forge_module_name, namespace
  end

  context "Setup initial module on filesystem" do
    include_context "Setup initial module on filesystem", initial_module_location, module_location
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

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Destroy service instance" do
    include_context "Destroy service instance", service_location, service_name
  end

  context "Uninstall module" do
    include_context "Uninstall module", module_name, module_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_location
  end

  # Cleanup of module imported from puppet forge
  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module_name.split(':').last
  end

  after(:all) do
    puts '', ''
  end
end
