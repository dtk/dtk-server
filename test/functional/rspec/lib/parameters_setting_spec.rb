require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context "Check attribute" do |dtk_common, node_name, name, value|
  it "confirms that value #{value} for attribute #{name} is present" do
    attribute_value_checked = dtk_common.check_attribute_presence_in_nodes(dtk_common.service_id, node_name, name, value)
    attribute_value_checked.should eq(true)
  end
end

shared_context "Check attribute present in component" do |dtk_common, node_name, component_name, name, value|
  it "checks value #{value} for attribute #{name} is present in #{component_name} component" do
    attribute_value_checked = dtk_common.check_attribute_presence_in_components(dtk_common.service_id, node_name, component_name, name, value)
    attribute_value_checked.should eq(true)
  end
end

shared_context "Get attribute value from component" do |dtk_common, node_name, component_name, attribute_name, value_to_match|
  it "gets value #{value_to_match} for attribute #{attribute_name} in #{component_name} component" do
    attribute_value = dtk_common.get_attribute_value(dtk_common.service_id, node_name, component_name, attribute_name)
    attribute_value.should match("#{value_to_match}")
  end
end

shared_context "Check attribute not present in component" do |dtk_common, node_name, component_name, name, value|
  it "checks value #{value} for attribute #{name} is not present in #{component_name} component" do
    attribute_value_checked = dtk_common.check_attribute_presence_in_components(dtk_common.service_id, node_name, component_name, name, value)
    attribute_value_checked.should eq(false)
  end
end

shared_context "Check param" do |dtk_common, node_name, name, value|
  it "confirms that value #{value} for param #{name} is present" do
    param_value_checked = dtk_common.check_params_presence_in_nodes(dtk_common.service_id, node_name, name, value)
    param_value_checked.should eq(true)
  end
end

shared_context "Check component" do |dtk_common, node_name, name|
  it "confirms that component #{name} is present on node #{node_name}" do
    param_value_checked = dtk_common.check_components_presence_in_nodes(dtk_common.service_id, node_name, name)
    param_value_checked.should eq(true)
  end
end

shared_context "Add component to service node" do |dtk_common, node_name, component_module, namespace|
  it "adds a component/s to #{node_name} node" do
    component_added_array = []
    pass = false
    dtk_common.component_module_name_list.each do |component_name|
      component_added_array << dtk_common.add_component_to_service_node(dtk_common.service_id, node_name, component_module + "::" + component_name, namespace)
    end
    # Check if component_added_array contains any element with false value.
    # That would indicate that particular component was not added successfully to the service node.
    pass = true if !component_added_array.include? false
    pass.should eq(true)
  end
end

shared_context "Add specific component to service node" do |dtk_common, node_name, component_name|
  it "adds #{component_name} component to #{node_name} node" do
    component_added = dtk_common.add_component_by_name_to_service_node(dtk_common.service_id, node_name, component_name)
    component_added.should eq(true)
  end
end

shared_context "Add specific component to service instance" do |dtk_common, component_name|
  it "adds #{component_name} component to service instance" do
    component_added = dtk_common.add_component_by_name_to_service_node(dtk_common.service_id, nil, component_name)
    component_added.should eq(true)
  end
end

shared_context "Set attribute" do |dtk_common, name, value|
  it "sets value #{value} for attribute #{name}" do
    attribute_value_set = dtk_common.set_attribute(dtk_common.service_id, name, value)
    attribute_value_set.should eq(true)
  end
end

shared_context "Set attribute on service level component" do |dtk_common, name, value|
  it "sets value #{value} for attribute #{name} on service level component" do
    attribute_value_set = dtk_common.set_attribute_on_service_level_component(dtk_common.service_id, name, value)
    attribute_value_set.should eq(true)
  end
end
