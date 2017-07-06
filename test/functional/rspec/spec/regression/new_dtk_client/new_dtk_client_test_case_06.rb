# This test script is used to test various options for adding/removing component links and service push
# Things that are under test are:
# - basic ability to auto-generate component links in dtk.service.yaml when assembly staged
# - ability to remove one component link from list and push
# - ability to remove complete component link list and push
# - ability to add one component link to list and push
# - ability to add complete component link list and push

require './lib/dtk_cli_spec'
require './lib/assembly_and_service_operations_spec'
require './lib/dtk_common'

update_1_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_06_1_dtk.service.yaml"
component_link_1_1 = { type: 'mysql::server', component_name: 'wordpress/wordpress::app', dependency_component: nil }
component_link_1_2 = { type: 'mysql::db', component_name: 'wordpress/wordpress::app', dependency_component: 'wordpress/mysql::db[wordpress]' }
component_link_1_3 = { type: 'wordpress::app', component_name: 'wordpress/wordpress::nginx_config', dependency_component: 'wordpress/wordpress::app' }

update_2_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_06_2_dtk.service.yaml"
component_link_2_1 = { type: 'mysql::server', component_name: 'wordpress/wordpress::app', dependency_component: nil }
component_link_2_2 = { type: 'mysql::db', component_name: 'wordpress/wordpress::app', dependency_component: 'wordpress/mysql::db[wordpress]' }
component_link_2_3 = { type: 'wordpress::app', component_name: 'wordpress/wordpress::nginx_config', dependency_component: nil }

update_3_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_06_3_dtk.service.yaml"
component_link_3_1 = { type: 'mysql::server', component_name: 'wordpress/wordpress::app', dependency_component: 'wordpress/mysql::server' }
component_link_3_2 = { type: 'mysql::db', component_name: 'wordpress/wordpress::app', dependency_component: 'wordpress/mysql::db[wordpress]' }
component_link_3_3 = { type: 'wordpress::app', component_name: 'wordpress/wordpress::nginx_config', dependency_component: nil }

update_4_service_location = "./spec/regression/new_dtk_client/resources/new_dtk_client_test_case_06_4_dtk.service.yaml"
component_link_4_1 = { type: 'mysql::server', component_name: 'wordpress/wordpress::app', dependency_component: 'wordpress/mysql::server' }
component_link_4_2 = { type: 'mysql::db', component_name: 'wordpress/wordpress::app', dependency_component: 'wordpress/mysql::db[wordpress]' }
component_link_4_3 = { type: 'wordpress::app', component_name: 'wordpress/wordpress::nginx_config', dependency_component: 'wordpress/wordpress::app' }

remote_module = 'dtk-examples/wordpress'
remote_module_location = '/tmp/new_dtk_client_test_case_06'
assembly_name = 'wordpress_single_node'
service_name = 'new_dtk_client_test_case_06'
service_location = '~/dtk/'
full_service_location = service_location + service_name

dtk_common = Common.new('', '')

describe "(New DTK client) Test Case 6: Test various options for adding/removing/autogenerating component links and service push" do
  before(:all) do
    puts '**********************************************************************************************************************', ''
  end

  context "Install module from dtkn" do
    include_context "Install module from dtkn", remote_module, remote_module_location, '1.5.0'
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", remote_module, assembly_name, dtk_common
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module", remote_module, remote_module_location, assembly_name, service_name
  end

  # check initial component dependencies
  context 'Check component dependencies' do
    include_context 'Check component dependencies', dtk_common, service_name, [ component_link_4_1, component_link_4_2, component_link_4_3 ]
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_1_service_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  # check component dependencies after removing one component link
  context 'Check component dependencies' do
    include_context 'Check component dependencies', dtk_common, service_name, [ component_link_1_1, component_link_1_2, component_link_1_3 ]
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_2_service_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  # check component dependencies after removing complete component link list
  context 'Check component dependencies' do
    include_context 'Check component dependencies', dtk_common, service_name, [ component_link_2_1, component_link_2_2, component_link_2_3 ]
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_3_service_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  # check component dependencies after reverting changes
  context 'Check component dependencies' do
    include_context 'Check component dependencies', dtk_common, service_name, [ component_link_3_1, component_link_3_2, component_link_3_3 ]
  end

  context "Change content of service instance on local filesystem" do
    include_context "Change content of service instance on local filesystem", full_service_location, update_4_service_location
  end

  context "Push service instance changes" do
    include_context "Push service instance changes", service_name, full_service_location
  end

  context 'Check component dependencies' do
    include_context 'Check component dependencies', dtk_common, service_name, [ component_link_4_1, component_link_4_2, component_link_4_3 ]
  end

  context "Delete service instance" do
    include_context "Delete service instance", service_location, service_name, dtk_common
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  context "Uninstall module" do
    include_context "Uninstall module", remote_module, remote_module_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", remote_module_location
  end

  after(:all) do
    puts '', ''
  end
end