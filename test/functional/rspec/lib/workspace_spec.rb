require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context "Create node in workspace" do |dtk_common, node_name, node_template|
  it "creates #{node_name} node from #{node_template} node template in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    node_created = dtk_common.create_node(workspace_id, node_name, node_template)
    node_created.should_not eq(nil)
  end
end

shared_context "Delete node in workspace" do |dtk_common, node_name|
  it "deletes #{node_name} node in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    node_deleted = dtk_common.delete_node(workspace_id, node_name)
    node_deleted.should eq(true)
  end
end

shared_context "Check node in workspace" do |dtk_common, node_name|
  it "checks that #{node_name} node exists in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    node_exists = dtk_common.check_if_node_exists_by_node_name(workspace_id, node_name)
    node_exists.should eq(true)
  end
end

shared_context "NEG - Check node in workspace" do |dtk_common, node_name|
  it "checks that #{node_name} node does not exist in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    node_exists = dtk_common.check_if_node_exists_by_node_name(workspace_id, node_name)
    node_exists.should eq(false)
  end
end

shared_context "Purge workspace content" do |dtk_common|
  it "removes all content in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    content_purged = dtk_common.purge_content(workspace_id)
    content_purged.should eq(true)
  end
end

shared_context "Add component to the node in workspace" do |dtk_common, node_name, component_name|
  it "adds #{component_name} component to #{node_name} node in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    component_added = dtk_common.add_component_to_service_node(workspace_id, node_name, component_name)
    component_added.should eq(true)
  end
end

shared_context "Workspace info" do |dtk_common, info_to_check|
  it "contains #{info_to_check}" do
    workspace_id = dtk_common.get_workspace_id
    info_checked = dtk_common.check_service_info(workspace_id, info_to_check)
    info_checked.should eq(true)
  end
end

shared_context "List components in workspace node" do |dtk_common, node_name, component_name|
  it "contains #{component_name} component in #{node_name} node in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    component_exists = dtk_common.check_components_presence_in_nodes(workspace_id, node_name, component_name)
    component_exists.should eq(true)
  end
end

shared_context "NEG - List components in workspace node" do |dtk_common, node_name, component_name|
  it "does not contain #{component_name} component in #{node_name} node in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    component_exists = dtk_common.check_components_presence_in_nodes(workspace_id, node_name, component_name)
    component_exists.should eq(false)
  end
end

shared_context "Delete component from workspace node" do |dtk_common, node_name, component_name|
  it "deletes #{component_name} component in #{node_name} node in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    component_deleted = dtk_common.delete_component_from_service_node(workspace_id, node_name, component_name)
    component_deleted.should eq(true)
  end
end

shared_context "Create attribute in workspace" do |dtk_common, attribute_name|
  it "creates #{attribute_name} attribute in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    attribute_created = dtk_common.create_attribute(workspace_id, attribute_name)
    attribute_created.should eq(true)
  end
end

shared_context "Set attribute value in workspace" do |dtk_common, attribute_name, attribute_value|
  it "sets #{attribute_value} value for #{attribute_name} attribute in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    attribute_value_set = dtk_common.set_attribute(workspace_id, attribute_name, attribute_value)
    attribute_value_set.should eq(true)
  end
end

shared_context "Check if attribute exists in workspace" do |dtk_common, attribute_name|
  it "verifies that  #{attribute_name} attribute exists in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    attribute_exists = dtk_common.check_if_attribute_exists(workspace_id, attribute_name)
    attribute_exists.should eq(true)
  end
end

shared_context "Check if value for attribute is set" do |dtk_common, node_name, attribute_name, attribute_value|
  it "verifies that  #{attribute_value} vlaue is set for #{attribute_name} attribute in workspace context" do
    workspace_id = dtk_common.get_workspace_id
    attribute_value_set = dtk_common.check_attribute_presence_in_nodes(workspace_id, node_name, attribute_name, attribute_value)
    attribute_value_set.should eq(true)
  end
end

shared_context "Link attributes" do |dtk_common, attribute_name_1, attribute_name_2|
  it "connects #{attribute_name_1} attribute to #{attribute_name_2} attribute" do
    workspace_id = dtk_common.get_workspace_id
    attributes_linked = dtk_common.link_attributes(workspace_id, attribute_name_1, attribute_name_2)
    attributes_linked.should eq(true)
  end
end

shared_context "Converge workspace" do |dtk_common|
  it "converges content of workspace" do
    workspace_id = dtk_common.get_workspace_id
    workspace_converged = dtk_common.converge_service(workspace_id)
    workspace_converged.should eq(true)
  end
end

shared_context "Start workspace" do |dtk_common|
  it "starts workspace that was stopped already" do
    workspace_id = dtk_common.get_workspace_id
    workspace_started = dtk_common.start_running_service(workspace_id)
    workspace_started.should eq(true)
  end
end

shared_context "Start workspace node" do |dtk_common, node_name|
  it "starts #{node_name} node that was stopped already in workspace" do
    workspace_id = dtk_common.get_workspace_id
    workspace_node_started = dtk_common.start_running_node(workspace_id, node_name)
    workspace_node_started.should eq(true)
  end
end

shared_context "Stop workspace" do |dtk_common|
  it "stops converged workspace" do
    workspace_id = dtk_common.get_workspace_id
    workspace_stopped = dtk_common.stop_running_service(workspace_id)
    workspace_stopped.should eq(true)
  end
end

shared_context "Stop workspace node" do |dtk_common, node_name|
  it "stops #{node_name} node in converged workspace" do
    workspace_id = dtk_common.get_workspace_id
    workspace_node_stopped = dtk_common.stop_running_node(workspace_id, node_name)
    workspace_node_stopped.should eq(true)
  end
end

shared_context "Grep log command" do |dtk_common, node_name, log_location, grep_pattern|
  it "finds #{grep_pattern} pattern in #{log_location} log on converged node" do
    workspace_id = dtk_common.get_workspace_id
    grep_pattern_found = dtk_common.grep_node(workspace_id, node_name, log_location, grep_pattern)
    grep_pattern_found.should eq(true)
  end
end

shared_context "Check if port avaliable" do |dtk_common, port|
  it "is avaliable" do
  	workspace_id = dtk_common.get_workspace_id
    netstat_response = dtk_common.netstats_check(workspace_id, port)
    netstat_response.should eq(true)
  end
end

shared_context "Check if port avaliable on specific node" do |dtk_common, node_name, port|
  it "is avaliable on #{node_name} node" do
  	workspace_id = dtk_common.get_workspace_id
    netstat_response = dtk_common.netstats_check_for_specific_node(workspace_id, node_name, port)
    netstat_response.should eq(true)
  end
end

shared_context "Create assembly from workspace content" do |dtk_common, service_module_name, assembly_name|
  it "creates assembly #{assembly_name} in #{service_module_name} service module" do
  	workspace_id = dtk_common.get_workspace_id
    assembly_created = dtk_common.create_assembly_from_service(workspace_id, service_module_name, assembly_name)
    assembly_created.should eq(true)
  end
end
