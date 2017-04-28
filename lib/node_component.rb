#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK
  class NodeComponent
    require_relative('node_component/type')
    # type must be before naming_class_mixin
    require_relative('node_component/naming_class_mixin')
    require_relative('node_component/attribute_mixin')
    require_relative('node_component/get_class_mixin')
    # instance_attributes must be before iaas
    require_relative('node_component/instance_attributes')
    require_relative('node_component/iaas')
    require_relative('node_component/parsing')


    extend NamingClassMixin
    include AttributeMixin
    extend GetClassMixin
    include InstanceAttributes::Mixin
    extend InstanceAttributes::ClassMixin

    attr_reader :component, :node, :assembly

    def initialize(assembly, node, component_with_attributes)
      @assembly  = assembly
      @node      = node
      @component = component_with_attributes.component
      # @ndx_attributes is indexed by symbolized attribute name
      @ndx_attributes = component_with_attributes.attributes.inject({}) { |h, attr| h.merge!(attr.display_name.to_sym => attr) } 
    end

    def node_group
      fail Error, "The method 'node_group' should not be called on a node component not associated with a node group" unless node.is_node_group?
      node.create_as_subclass_object(NodeGroup)
    end

    def assembly_name
      assembly.display_name
    end

    def node_name
      node.display_name
    end


    # returns an array of DTK::NodeComponents
    def self.node_components(nodes, assembly)
      # indexed by display_name
      ndx_nodes = nodes.inject({}) { |h, node | h.merge(node.display_name => node) }
      get_components_with_attributes(nodes, assembly).map do |component_with_attr|
        component = component_with_attr.component
        node      = ndx_nodes[node_name(component)]
        IAAS.create(assembly, node, component_with_attr) 
      end
    end

    # returns a DTK::NodeComponent object
    def self.node_component_from_node(node)
      node_components([node], assembly_from_node(node)).first || 
        fail(Error, "Unexpected that there is no node component associated with node object '#{node.display_name}'")
    end

    # returns a DTK::NodeComponent object if the component is a node component
    def self.node_component?(component)
      component.update_object!(:component_type, :assembly_id)
      if is_node_component?(component)
        assembly = assembly_from_component(component)
        node     = node_from_component(component, assembly)
        IAAS.create(assembly, node, component_with_attributes(component))
      end
    end
    def self.node_component(component)
      node_component?(component) || fail(Error, "Unexpected that component '#{component.display_name}' is not a node component")
    end

    # returns true if component is a node component 
    def self.is_node_component?(component)
      NodeComponent.component_types.include?(component.get_field?(:component_type))
    end

    private

    def self.component_types
      @component_types ||= IAAS::TYPES.inject([]) { |a, iaas_type| a + node_component_types(iaas_type) }
    end

    def self.node_name(component)
      if component.display_name =~ /\[(.+)\]$/
        $1
      else
        fail Error, "Unexpected that display_name '#{component.display_name}' is not of form IAAS_node[NAME]"
      end
    end

    def self.assembly_from_component(component)
      component.model_handle.createIDH(model_name: :assembly_instance, id: component.get_field?(:assembly_id)).create_object
    end

    def self.assembly_from_node(node)
      node.model_handle.createIDH(model_name: :assembly_instance, id: node.get_field?(:assembly_id)).create_object
    end

  end
end
