require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context 'Check if service module version exists on server' do |dtk_common, service_module_name, version_name|
  it "checks that service module #{service_module_name} with version #{version_name} exists on server" do
    service_module_version_exists = dtk_common.check_service_module_version(service_module_name, version_name)
    expect(service_module_version_exists).to eq(true)
  end
end

shared_context 'NEG - Check if service module version exists on server' do |dtk_common, service_module_name, version_name|
  it "checks that service module #{service_module_name} with version #{version_name} does not exist on server" do
    service_module_version_exists = dtk_common.check_service_module_version(service_module_name, version_name)
    expect(service_module_version_exists).to eq(false)
  end
end

shared_context 'Check if service module version exists on remote' do |dtk_common, service_module_name, version_name|
  it "checks that service module #{service_module_name} with version #{version_name} exists on remote" do
    service_module_version_exists = dtk_common.check_service_module_remote_versions(service_module_name, version_name)
    expect(service_module_version_exists).to eq(true)
  end
end

shared_context 'NEG - Check if service module version exists on remote' do |dtk_common, service_module_name, version_name|
  it "checks that service module #{service_module_name} with version #{version_name} does not exist on remote" do
    service_module_version_exists = dtk_common.check_service_module_remote_versions(service_module_name, version_name)
    expect(service_module_version_exists).to eq(false)
  end
end

shared_context 'Publish versioned service module' do |dtk_common, service_module_name, version_name|
	it "publish/push service module #{service_module_name} with version #{version_name}" do
		service_module_published = dtk_common.publish_service_module_version(service_module_name, version_name)
		expect(service_module_published).to eq(true)
	end
end

shared_context 'NEG - Publish versioned service module' do |dtk_common, service_module_name, version_name|
	it "does not publish/push service module #{service_module_name} since this version #{version_name} does not exist" do
		service_module_published = dtk_common.publish_service_module_version(service_module_name, version_name)
		expect(service_module_published).to eq(false)
	end
end