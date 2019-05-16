# Test case 4: Destroy kubernetes base cluster and all connected services

require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_cli_spec'
require './lib/app_sanity_check_spec.rb'

service_instance_location = '~/dtk/'

base_cluster_name = 'kubernetes_base_cluster_unit_test_1'

dtk_common = Common.new('', '')

describe 'Test case 4: Destroy kubernetes base cluster' do
  before(:all) do
    puts '************************************************************************************************', ''
  end

  context 'Destroy kubernetes base cluster instance' do
    include_context 'Destroy service instance', service_instance_location, base_cluster_name
  end

  after(:all) do
    puts '', ''
  end
end