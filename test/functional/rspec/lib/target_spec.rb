require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context "Create target" do |dtk_common, provider_name, region|
	it "creates new target #{provider_name}-#{region}" do
		target_created = dtk_common.create_target(provider_name, region)
		target_created.should eq(true)
	end
end

shared_context "Check if target exists in provider" do |dtk_common, provider_name, target_name|
	it "exists in provider #{provider_name}" do
		target_exists = dtk_common.check_if_target_exists_in_provider(provider_name, target_name)
		target_exists.should eq(true)
	end
end

shared_context "NEG - Check if target exists in provider" do |dtk_common, provider_name, target_name|
	it "does not exist in provider #{provider_name}" do
		target_exists = dtk_common.check_if_target_exists_in_provider(provider_name, target_name)
		target_exists.should eq(false)
	end
end

shared_context "Delete target" do |dtk_common, target_name|
	it "deletes target #{target_name}" do
		target_deleted = dtk_common.delete_target_from_provider(target_name)
		target_deleted.should eq(true)
	end
end

shared_context "Check if assembly exists in target" do |dtk_common, assembly_name, target_name|
	it "exists in target #{target_name}" do
		assembly_exists = dtk_common.check_if_assembly_exists_in_target(assembly_name, target_name)
		assembly_exists.should eq(true)
	end
end

shared_context "Check if node exists in target" do |dtk_common, node_name, target_name|
	it "exists in target #{target_name}" do
		node_exists = dtk_common.check_if_node_exists_in_target(node_name, target_name)
		node_exists.should eq(true)
	end
end

shared_context "Stage service in specific target" do |dtk_common, target_name|
	it "stages #{dtk_common.service_name} service from assembly #{dtk_common.assembly} in target #{target_name}" do
		dtk_common.stage_service_in_specific_target(target_name)
		dtk_common.service_id.should_not eq(nil)
	end
end