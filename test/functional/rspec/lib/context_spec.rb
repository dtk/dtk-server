require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context 'Set default context' do |dtk_common, context_name|
  it "sets #{context_name} as default context" do
    default_context_set = dtk_common.set_default_context(context_name)
    default_context_set.should eq(true)
  end
end

shared_context 'Create context' do |dtk_common, provider_name, region|
  it "creates new context #{provider_name}-#{region}" do
    context_created = dtk_common.create_context(provider_name, region)
    context_created.should eq(true)
  end
end

shared_context 'Check if context exists in provider' do |dtk_common, provider_name, context_name|
  it "exists in provider #{provider_name}" do
    context_exists = dtk_common.check_if_context_exists_in_provider(provider_name, context_name)
    context_exists.should eq(true)
  end
end

shared_context 'NEG - Check if context exists in provider' do |dtk_common, provider_name, context_name|
  it "does not exist in provider #{provider_name}" do
    context_exists = dtk_common.check_if_context_exists_in_provider(provider_name, context_name)
    context_exists.should eq(false)
  end
end

shared_context 'Delete context' do |dtk_common, context_name|
  it "deletes context #{context_name}" do
    context_deleted = dtk_common.delete_context_from_provider(context_name)
    context_deleted.should eq(true)
  end
end

shared_context 'Check if assembly exists in context' do |dtk_common, assembly_name, context_name|
  it "exists in context #{context_name}" do
    assembly_exists = dtk_common.check_if_assembly_exists_in_context(assembly_name, context_name)
    assembly_exists.should eq(true)
  end
end

shared_context 'Check if node exists in context' do |dtk_common, node_name, context_name|
  it "exists in context #{context_name}" do
    node_exists = dtk_common.check_if_node_exists_in_context(node_name, context_name)
    node_exists.should eq(true)
  end
end

shared_context 'Stage service in specific context' do |dtk_common, context_name|
  it "stages #{dtk_common.service_name} service from assembly #{dtk_common.assembly} in context #{context_name}" do
    dtk_common.stage_service_in_specific_context(context_name)
    dtk_common.service_id.should_not eq(nil)
  end
end

shared_context 'Delete default context' do |dtk_common|
  it "deletes default context" do
    context_id = dtk_common.get_default_context
    context_deleted = dtk_common.delete_and_destroy_service(context_id)
    context_deleted.should eq(true)
  end
end
