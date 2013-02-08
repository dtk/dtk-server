require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './test/lib/dtk_common'

STDOUT.sync = true

shared_context "Stage" do |dtk_common|
	it "stages assembly from assembly template" do
		$assembly_id = dtk_common.stage_assembly()
		$assembly_id.should_not eq(nil)
		puts "Stage completed successfully!"
	end
end

shared_context "List assemblies after stage" do |dtk_common|
	unless $assembly_id.nil?
		it "has staged assembly in assembly list" do
			assembly_exists = dtk_common.check_if_assembly_exists($assembly_id)
			assembly_exists.should eq(true)
			puts "Assembly exists in assembly list."
		end
	end
end

shared_context "Delete assemblies" do |dtk_common|
	unless $assembly_id.nil?
		it "deletes assembly" do
			assembly_deleted = dtk_common.delete_and_destroy_assembly($assembly_id)
			assembly_deleted.should eq("ok")
			puts "Assembly deleted successfully!"
		end
	end
end

shared_context "List assemblies after delete" do |dtk_common|
	unless $assembly_id.nil?
		it "doesn't have assembly in assembly list" do
			assembly_exists = dtk_common.check_if_assembly_exists($assembly_id)
			assembly_exists.should eq(false)
			puts "Assembly does not exist in assembly list since it was deleted previously."
		end
	end
end

shared_context "Set attribute" do |dtk_common, name, value|
	unless $assembly_id.nil?
		attribute_value_set = dtk_common.set_attribute($assembly_id, name, value)
		it "sets value #{value} for attribute #{name}" do
			attribute_value_set.should eq(true)
			puts "Attribute value set for assembly."
		end
	end
end

shared_context "Check attribute" do |dtk_common, node_name, name, value|
	unless $assembly_id.nil?
		it "has value #{value} for attribute #{name} present" do
			attribute_value_checked = dtk_common.check_attribute_presence_in_nodes($assembly_id, node_name, name, value)
			attribute_value_checked.should eq(true)
			puts "Attribute value exists for assembly."
		end
	end
end

shared_context "Check param" do |dtk_common, node_name, name, value|
	unless $assembly_id.nil?
		it "has value #{value} for param #{name} present" do
			param_value_checked = dtk_common.check_params_presence_in_nodes($assembly_id, node_name, name, value)
			param_value_checked.should eq(true)
			puts "Node param value exists for assembly."
		end
	end
end

shared_context "Check component" do |dtk_common, node_name, name|
	unless $assembly_id.nil?
		it "has component #{name} present" do
			param_value_checked = dtk_common.check_components_presence_in_nodes($assembly_id, node_name, name)
			param_value_checked.should eq(true)
			puts "Component exists for assembly."
		end
	end
end

shared_context "Converge" do |dtk_common|
	unless $assembly_id.nil?
		it "converges assembly" do
			converge = dtk_common.converge_assembly($assembly_id)
			converge.should eq("succeeded")
			puts "Assembly converged successfully!"
		end
	end
end

shared_context "Stop assembly" do |dtk_common|
	unless $assembly_id.nil?
		it "stops assembly" do
			stop_status = dtk_common.stop_running_assembly($assembly_id)
			stop_status.should eq("ok")
			puts "Assembly stopped successfully!"
		end
	end
end

shared_context "Check if port avaliable" do |dtk_common, port|
	unless $assembly_id.nil?
		it "exists" do
			netstat_response = dtk_common.netstats_check($assembly_id)
			namenode_port = netstat_response['data']['results'].select { |x| x['port'] == port}.first['port']
			namenode_port.should eq(port)
			puts "Service up and running on deployed instance (port #{port} avaliable)."
		end
	end
end