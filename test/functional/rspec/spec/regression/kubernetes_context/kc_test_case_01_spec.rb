# Test case 1: Install kubernetes module, stage and converge cluster

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'

remote_module = 'kubernetes:kubernetes'
remote_module_location = '~/dtk/modules/tests/kubernetes'
version = 'master';

assembly_name = 'cluster'

service_instance_location = '~/dtk/'
service_instance_name = 'kubernetes_cluster'

dtk_common = Common.new('', '')

describe 'Test case 1: Install kubernetes module, stage and converge cluster' do
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

  after(:all) do
    puts '', ''
  end
end