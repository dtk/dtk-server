require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

shared_context "Check attribute" do |dtk_common, node_name, name, value|
  it "confirms that value #{value} for attribute #{name} is present" do
    attribute_value_checked = dtk_common.check_attribute_presence_in_nodes($assembly_id, node_name, name, value)
    attribute_value_checked.should eq(true)
  end
end

shared_context "Check attribute present in component" do |dtk_common, node_name, component_name, name, value|
  it "checks value #{value} for attribute #{name} is present in #{component_name} component" do
    attribute_value_checked = dtk_common.check_attribute_presence_in_components($assembly_id, node_name, component_name, name, value)
    attribute_value_checked.should eq(true)
  end
end

shared_context "Check attribute not present in component" do |dtk_common, node_name, component_name, name, value|
  it "checks value #{value} for attribute #{name} is not present in #{component_name} component" do
    attribute_value_checked = dtk_common.check_attribute_presence_in_components($assembly_id, node_name, component_name, name, value)
    attribute_value_checked.should eq(false)
  end
end

shared_context "Check param" do |dtk_common, node_name, name, value|
  it "confirms that value #{value} for param #{name} is present" do
    param_value_checked = dtk_common.check_params_presence_in_nodes($assembly_id, node_name, name, value)
    param_value_checked.should eq(true)
  end
end

shared_context "Check component" do |dtk_common, node_name, name|
  it "confirms that component #{name} is present on node #{node_name}" do
    param_value_checked = dtk_common.check_components_presence_in_nodes($assembly_id, node_name, name)
    param_value_checked.should eq(true)
  end
end

shared_context "Add component to assembly node" do |dtk_common, node_name|
  it "adds a component/s to #{node_name} node" do
    component_added_array = Array.new()
    pass = false
    dtk_common.component_module_id_list.each do |component_id|
      component_added_array << dtk_common.add_component_to_assembly_node($assembly_id, node_name, component_id)
    end
    pass = true if !component_added_array.include? false
    pass.should eq(true)
  end
end

shared_context "Add specific component to assembly node" do |dtk_common, node_name, component_name|
  it "adds #{component_name} component to #{node_name} node" do
    component_added = dtk_common.add_component_by_name_to_assembly_node($assembly_id, node_name, component_name)
    component_added.should eq(true)
  end
end

shared_context "Set attribute" do |dtk_common, name, value|
  it "sets value #{value} for attribute #{name}" do
    attribute_value_set = dtk_common.set_attribute($assembly_id, name, value)
    attribute_value_set.should eq(true)
  end
end