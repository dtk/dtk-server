require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context 'Stage node template' do |dtk_common, node_name, staged_node_name|
  it "stages #{node_name} node template to #{staged_node_name} node" do
    dtk_common.stage_node_template(node_name, staged_node_name)
    dtk_common.node_id.should_not eq(nil)
  end
end

shared_context 'List nodes after stage' do |dtk_common, staged_node_name|
  it "has staged #{staged_node_name} node in node list" do
    node_exists = dtk_common.check_if_node_exists(dtk_common.node_id)
    node_exists.should eq(true)
  end
end

shared_context 'Converge node' do |dtk_common, staged_node_name|
  it "converges #{staged_node_name} node" do
    converge = dtk_common.converge_node(dtk_common.node_id)
    converge.should eq(true)
  end
end

shared_context 'Add component to node' do |dtk_common, staged_node_name, component_name|
  it "adds a #{component_name} component to #{staged_node_name} node" do
    component_added = dtk_common.add_component_to_node(dtk_common.node_id, component_name)
    component_added.should eq(true)
  end
end

shared_context 'Set node attribute' do |dtk_common, staged_node_name, name, value|
  it "sets value #{value} for attribute #{name} on #{staged_node_name} node" do
    attribute_value_set = dtk_common.set_attribute_on_node(dtk_common.node_id, name, value)
    attribute_value_set.should eq(true)
  end
end

shared_context 'get-netstats function on node' do |dtk_common, staged_node_name, port_to_check|
  it "checks port #{port_to_check} are avaliable on #{staged_node_name} node" do
    ports_avaliable = dtk_common.check_get_netstats(dtk_common.node_id, port_to_check)
    ports_avaliable.should eq(true)
  end
end

shared_context 'list-task-info function on node' do |dtk_common, _staged_node_name, component_name|
  it "checks task status contains #{component_name} component, source is instance and it does not belong to any node group" do
    task_info_status_success = dtk_common.check_list_task_info_status(dtk_common.node_id, component_name)
    task_info_status_success.should eq(true)
  end
end

shared_context 'Delete component from service' do |dtk_common, node_name, component_name|
  it "deletes component #{component_name}" do
    component_deleted = dtk_common.delete_component_from_service(dtk_common.service_id, node_name, component_name)
    expect(component_deleted).to eq(true)
  end
end

shared_context 'Destroy node' do |dtk_common, staged_node_name|
  it "destroys #{staged_node_name} node" do
    node_deleted = dtk_common.destroy_node(dtk_common.node_id)
    node_deleted.should eq(true)
  end
end
