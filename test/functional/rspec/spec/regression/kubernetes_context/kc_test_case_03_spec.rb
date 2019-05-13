# Test case 3: Install kubernetes/kubernetes_grafana module, stage to context with kubernetes base cluster, converge

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'
require './lib/app_sanity_check_spec.rb'

remote_module = 'kubernetes:kubernetes_grafana'
remote_module_location = '~/dtk/modules/tests/kubernetes_grafana'
version = 'master'

service_instance_location = '~/dtk/'
service_instance_name = 'grafana_unit_test'
context_name = 'kubernetes_base_cluster_unit_test_1'
node_name = 'master'

assembly_name = 'unit_test'

dtk_common = Common.new('', '')

describe 'Test case 3: Install kubernetes/kubernetes_grafana module, stage to context with kubernetes base cluster, converge' do
  before(:all) do
    puts '************************************************************************************************', ''
  end

  context 'Install module from dtkn' do
    include_context 'Install module from dtkn', remote_module, remote_module_location, version
  end

  context 'List assemblies' do
    include_context 'List assemblies', remote_module, assembly_name, dtk_common
  end

  context 'Stage assembly from module to specific context' do
    include_context 'Stage assembly from module to specific context', remote_module, remote_module_location, assembly_name, service_instance_name, context_name
  end

  context 'Converge service instance' do
    include_context 'Converge service instance', service_instance_location, dtk_common, service_instance_name
  end

  context 'Grafana sanity check' do
    include_context 'Sanity check of grafana instance', dtk_common, context_name, node_name
  end  

  after(:all) do
    puts '', ''
  end
end