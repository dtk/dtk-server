require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

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

shared_context "Delete assembly template" do |dtk_common, assembly_template_name|
	it "deletes assembly template" do
		assembly_template_deleted = dtk_common.delete_assembly_template(assembly_template_name)
		assembly_template_deleted.should eq("ok")
		puts "Assembly template deleted successfully!"
	end
end

shared_context "Create assembly template from assembly" do |dtk_common, service_name, assembly_template_name|
	it "creates assembly template in given service from existing assembly" do
		assembly_template_created = dtk_common.create_assembly_template_from_assembly($assembly_id, service_name, assembly_template_name)
		assembly_template_created.should eq(true)
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
		it "sets value #{value} for attribute #{name}" do
			attribute_value_set = dtk_common.set_attribute($assembly_id, name, value)
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

shared_context "Import remote module" do |module_name|
	it "imports module from remote repo" do
		pass = false
		value = `dtk module import #{module_name}`
		pass = value.include? "module_directory:"
		pass.should eq(true)
	end
end

shared_context "Import versioned module from remote" do |dtk_common, module_name, version|
	it "checks existance of module and imports versioned module from remote repo" do
		module_imported = dtk_common.import_versioned_module_from_remote(module_name, version)
		module_imported.should eq(true)
	end
end

shared_context "Get module components list" do |dtk_common, module_name|
	it "gets list of all components modules" do
		$module_components_list = dtk_common.get_module_components_list(module_name, "")
		empty_list = $module_components_list.empty?
		empty_list.should eq(false)
	end
end

shared_context "Get versioned module components list" do |dtk_common, module_name, version|
	it "gets list of components modules from version #{version}" do
		$versioned_module_components_list = dtk_common.get_module_components_list(module_name, version)
		empty_list = $versioned_module_components_list.empty?
		empty_list.should eq(false)
	end
end

shared_context "Add component to assembly node" do |dtk_common, node_name, component_id|
	it "adds a component to assembly node" do
		component_added = dtk_common.add_component_to_assembly_node($assembly_id, node_name, component_id)
		component_added.should eq(true)
	end
end

shared_context "Delete module" do |dtk_common, module_name|
	it "deletes module from server" do
		module_deleted = dtk_common.delete_module(module_name)
		module_deleted.should eq(true)
	end
end

shared_context "Delete module from local filesystem" do |module_filesystem_location, module_name|
	it "deletes module from local filesystem" do
		pass = false
		value = `rm -rf #{module_filesystem_location}/#{module_name}`
		pass = !value.include?("cannot remove")
		pass.should eq(true)
	end
end

shared_context "Delete versioned module from local filesystem" do |module_filesystem_location, module_name, module_version|
	it "deletes versioned module from local filesystem" do
		pass = false
		value = `rm -rf #{module_filesystem_location}/#{module_name}-#{module_version}`
		pass = !value.include?("cannot remove")
		pass.should eq(true)
	end
end

shared_context "Check module imported on local filesystem" do |module_filesystem_location, module_name|
	it "checks if module imported on local filesystem" do
		pass = false
		value = `ls #{module_filesystem_location}/#{module_name}`
		pass = !value.include?("No such file or directory")
		pass.should eq(true)
	end
end

shared_context "Clone versioned module" do |dtk_common, module_name, module_version|
	it "clones versioned module from server to local filesystem" do
		pass = false
		value = `dtk module #{module_name} clone -v #{module_version} -n`
		pass = value.include?("Module #{module_name} has been successfully cloned!")
		pass.should eq(true)
	end
end

shared_context "Check versioned module imported on local filesystem" do |module_filesystem_location, module_name, module_version|
	it "checks if versioned module imported on local filesystem" do
		pass = false
		value = `ls #{module_filesystem_location}/#{module_name}-#{module_version}`
		pass = !value.include?("No such file or directory")
		pass.should eq(true)
	end
end

shared_context "Create new module version" do |dtk_common, module_name, version|
	it "creates new module version on server" do
		module_versioned = dtk_common.create_new_module_version(module_name, version)
		module_versioned.should eq(true)
	end
end

shared_context "Create service" do |dtk_common, service_name|
	it "creates new service module" do
		service_created = dtk_common.create_new_service(service_name)
		service_created.should eq(true)
	end
end

shared_context "Delete service" do |dtk_common, service_name|
	it "deletes service module" do
		service_deleted = dtk_common.delete_service(service_name)
		service_deleted.should eq(true)
	end
end

shared_context "Check if assembly template belongs to the service" do |dtk_common, service_name, assembly_template_name|
	it "verifes that assembly template is part of the service" do
		template_exists_in_service = dtk_common.check_if_service_contains_assembly_template(service_name, assembly_template_name)
		template_exists_in_service.should eq(true)
	end
end