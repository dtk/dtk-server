require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

shared_context "Check attribute" do |dtk_common, node_name, name, value|
  unless $assembly_id.nil?
    it "has value #{value} for attribute #{name} present" do
      attribute_value_checked = dtk_common.check_attribute_presence_in_nodes($assembly_id, node_name, name, value)
      attribute_value_checked.should eq(true)
      puts "Attribute value exists for assembly."
    end
  end
end

shared_context "Check attribute present in component" do |dtk_common, node_name, component_name, name, value|
  unless $assembly_id.nil?
    it "checks value #{value} for attribute #{name} is present" do
      attribute_value_checked = dtk_common.check_attribute_presence_in_components($assembly_id, node_name, component_name, name, value)
      attribute_value_checked.should eq(true)
      puts "Attribute exists for component #{component_name} in assembly."
    end
  end
end

shared_context "Check attribute not present in component" do |dtk_common, node_name, component_name, name, value|
  unless $assembly_id.nil?
    it "check value #{value} for attribute #{name} is not present" do
      attribute_value_checked = dtk_common.check_attribute_presence_in_components($assembly_id, node_name, component_name, name, value)
      attribute_value_checked.should eq(false)
      puts "Attribute does not exist for component #{component_name} in assembly."
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

shared_context "Add component to assembly node" do |dtk_common, node_name, component_id|
  it "adds a component to assembly node" do
    component_added = dtk_common.add_component_to_assembly_node($assembly_id, node_name, component_id)
    component_added.should eq(true)
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