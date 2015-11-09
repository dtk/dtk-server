require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context 'Check if component module version exists on server' do |dtk_common, component_module_name, version_name|
  it "checks that component module #{component_module_name} with version #{version_name} exists on server" do
    component_module_version_exists = dtk_common.check_component_module_version(component_module_name, version_name)
    expect(component_module_version_exists).to eq(true)
  end
end

shared_context 'NEG - Check if component module version exists on server' do |dtk_common, component_module_name, version_name|
  it "checks that component module #{component_module_name} with version #{version_name} does not exist on server" do
    component_module_version_exists = dtk_common.check_component_module_version(component_module_name, version_name)
    expect(component_module_version_exists).to eq(false)
  end
end

shared_context 'Check if component module version exists on remote' do |dtk_common, component_module_name, version_name|
  it "checks that component module #{component_module_name} with version #{version_name} exists on remote" do
    component_module_version_exists = dtk_common.check_component_module_remote_versions(component_module_name, version_name)
    expect(component_module_version_exists).to eq(true)
  end
end

shared_context 'NEG - Check if component module version exists on remote' do |dtk_common, component_module_name, version_name|
  it "checks that component module #{component_module_name} with version #{version_name} does not exist on remote" do
    component_module_version_exists = dtk_common.check_component_module_remote_versions(component_module_name, version_name)
    expect(component_module_version_exists).to eq(false)
  end
end

shared_context 'Set attribute on versioned component' do |dtk_common, component_module_name, version_name, attribute_name, attribute_value|
	it "sets attribute value #{attribute_value} for attribute #{attribute_name}" do
		attribute_set = dtk_common.set_attribute_on_versioned_component(component_module_name, component_name, attribute_name, attribute_value, version_name)
		expect(attribute_set).to eq(true)
	end
end

shared_context 'Add versioned component to service' do |dtk_common, namespace, component_name, version_name, service_name, node_name|
	it "adds component #{component_name} with version #{version_name} to service #{service_name} on node #{node_name}" do
		component_added = dtk_common.add_versioned_component_to_service(namespace, component_name, version_name, service_name, node_name)
		expect(component_added).to eq(true)
	end
end

shared_context 'NEG - Add versioned component to service' do |dtk_common, namespace, component_name, version_name, service_name, node_name|
	it "does not addd component #{component_name} with version #{version_name} since it does not exist" do
		component_added = dtk_common.add_versioned_component_to_service(namespace, component_name, version_name, service_name, node_name)
		expect(component_added).to eq(false)
	end
end

shared_context 'Publish versioned component module' do |dtk_common, component_module_name, version_name|
	it "publish/push component module #{component_module_name} with version #{version_name}" do
		component_module_published = dtk_common.publish_component_module_version(component_module_name, version_name)
		expect(component_module_published).to eq(true)
	end
end

shared_context 'NEG - Publish versioned component module' do |dtk_common, component_module_name, version_name|
	it "does not publish/push component module #{component_module_name} since this version #{version_name} does not exist" do
		component_module_published = dtk_common.publish_component_module_version(component_module_name, version_name)
		expect(component_module_published).to eq(false)
	end
end