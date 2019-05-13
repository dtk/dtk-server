# Test case 2: Install kubernetes/kubernetes_base_cluster module, stage unit test and converge
# Also installs local storage and prometheus on cluster

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'
require './lib/app_sanity_check_spec.rb'

remote_module = 'kubernetes:kubernetes_base_cluster'
remote_module_location = '~/dtk/modules/tests/kubernetes_base_cluster'
version = 'master'

service_instance_location = '~/dtk/'
service_instance_name = 'kubernetes_base_cluster_unit_test_1'

assembly_name = 'unit_test_1'
node_name = 'master'

dtk_common = Common.new('', '')

describe 'Test case 2: Install kubernetes/kubernetes_base_cluster module, stage unit test and converge' do
  before(:all) do
    puts '************************************************************************************************', ''
  end

  context 'Install module from dtkn' do
    include_context 'Install module from dtkn', remote_module, remote_module_location, version
  end

  context 'List assemblies' do
    include_context 'List assemblies', remote_module, assembly_name, dtk_common
  end

  context 'Stage assembly from module' do
    include_context 'Stage assembly from module', remote_module, remote_module_location, assembly_name, service_instance_name
  end

  context 'Converge service instance' do
    include_context 'Converge service instance', service_instance_location, dtk_common, service_instance_name
  end

  context 'Prometheus sanity check' do
    include_context 'Sanity check of prometheus instance', dtk_common, service_instance_name, node_name
  end

  after(:all) do
    puts '', ''
  end
end