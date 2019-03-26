# This test script is used to test deployment of getting started example: kubernetes/kubernetes and rails/rails_sample_app
# Things that are under test are:
# - ability to stage and converge kubernetes cluster which will serve as context for rails application
# - ability to stage and converge rails application in the context of kubernetes cluster

require './lib/dtk_cli_spec'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

kubernetes_assembly_name = 'cluster'
kubernetes_service_name = "kubernetes_cluster" + rand(10..1000).to_s
kubernetes_remote_module = 'kubernetes/kubernetes'
kubernetes_remote_module_location = '/tmp/kubernetes'
kubernetes_remote_module_version = '1.3.0'

rails_assembly_name = 'on_kubernetes_with_db'
rails_service_name = "rails_sample_app" + rand(10..1000).to_s
rails_remote_module = 'rails/rails_sample_app'
rails_remote_module_location = '/tmp/rails'
rails_remote_module_version = '1.2.0'

service_location = '~/dtk/'

dtk_common = Common.new('', '')

describe "Getting started example: kubernetes/kubernetes and rails/rails_sample_app" do
  before(:all) do
    puts '*************************************************************************', ''
  end

  context "Install kubernetes module from dtkn" do
    include_context "Install module from dtkn", kubernetes_remote_module, kubernetes_remote_module_location, kubernetes_remote_module_version
  end

  context "List assemblies contained in kubernetes module" do
    include_context "List assemblies", kubernetes_remote_module, kubernetes_assembly_name, dtk_common
  end

  context "Stage kubernetes assembly from module" do
    include_context "Stage assembly from module", kubernetes_remote_module, kubernetes_remote_module_location, kubernetes_assembly_name, kubernetes_service_name
  end

  context "Converge kubernetes service instance" do
    include_context "Converge service instance", service_location, dtk_common, kubernetes_service_name
  end

  context "Install rails module from dtkn" do
    include_context "Install module from dtkn", rails_remote_module, rails_remote_module_location, rails_remote_module_version
  end

  context "List assemblies contained in rails module" do
    include_context "List assemblies", rails_remote_module, rails_assembly_name, dtk_common
  end

  context "Stage rails assembly from module" do
    include_context "Stage assembly from module to specific context", rails_remote_module, rails_remote_module_location, rails_assembly_name, rails_service_name, kubernetes_service_name
  end

  context "Converge rails service instance" do
    include_context "Converge service instance", service_location, dtk_common, rails_service_name
  end

  context "Delete rails service instance" do
    include_context "Delete service instance", service_location, rails_service_name, dtk_common
  end

  context "Uninstall rails service instance" do
    include_context "Uninstall service instance", service_location, rails_service_name
  end

  context "Uninstall rails module" do
    include_context "Uninstall module", rails_remote_module, rails_remote_module_location
  end

  context "Delete initial rails module on filesystem" do
    include_context "Delete initial module on filesystem", rails_remote_module_location
  end

  context "Check that rails service instance nodes have been terminated on aws" do
    include_context "Check that service instance nodes have been terminated on aws", dtk_common, rails_service_name
  end

  context "Delete kubernetes service instance" do
    include_context "Delete service instance", service_location, kubernetes_service_name, dtk_common
  end

  context "Uninstall kubernetes service instance" do
    include_context "Uninstall service instance", service_location, kubernetes_service_name
  end

  context "Uninstall kubernetes module" do
    include_context "Uninstall module", kubernetes_remote_module, kubernetes_remote_module_location
  end

  context "Delete initial kubernetes module on filesystem" do
    include_context "Delete initial module on filesystem", kubernetes_remote_module_location
  end

  context "Check that kubernetes service instance nodes have been terminated on aws" do
    include_context "Check that service instance nodes have been terminated on aws", dtk_common, kubernetes_service_name
  end

  after(:all) do
    puts '', ''
  end
end