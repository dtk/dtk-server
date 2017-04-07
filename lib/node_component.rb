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
  module NodeComponent
    require_relative('node_component/parsing')
    require_relative('node_component/iaas')

    def self.node_components(nodes, assembly)
      assembly_name = assembly.display_name
      get_components_with_attributes(nodes, assembly).map do |component_with_attr|
        component = component_with_attr.component
        IAAS.create(iaas_type(component), assembly_name, node_name(component), component_with_attr) 
      end
    end

    def self.set_special_node_component_attributes(nodes, assembly)
      node_components(nodes, assembly).each { |node_component| node_component.set_special_attributes }
    end

    NODE_COMPONENT_COMPONENT = 'node'
    COMPONENT_TYPE_DELIM = '__'
    COMPONENT_TYPE_DISPLAY_NAME_DEMILM = '::'
    def self.node_component_type(iaas_type)
      "#{iaas_type}#{COMPONENT_TYPE_DELIM}#{NODE_COMPONENT_COMPONENT}"
    end

    def self.node_component_type_display_name(iaas_type)
      "#{iaas_type}#{COMPONENT_TYPE_DISPLAY_NAME_DEMILM}#{NODE_COMPONENT_COMPONENT}"
    end

    def self.node_component_ref(iaas_type, node_name)
      "#{node_component_type_display_name(iaas_type)}[#{node_name}]"
    end

    ASSEMBLY_WIDE_NODE_NAME = 'assembly_wide'
    def self.node_component_ref_from_node(node)
      # TODO: DTK-2967: below hard-wired to ec2
      node.is_assembly_wide_node? ? ASSEMBLY_WIDE_NODE_NAME : node_component_ref(:ec2, node.display_name)
    end

    def self.component_types
      @component_types ||= IAAS::TYPES.map { |iaas_type| node_component_type(iaas_type) }
    end

    private

    def self.get_components_with_attributes(nodes, assembly)
      Component::Instance::WithAttributes.components_with_attributes(get_components(nodes, assembly))
    end

    COMPONENT_COLS = [:id, :group_id, :display_name, :component_type]
    def self.get_components(nodes, assembly)
      ret = []
      return ret if nodes.empty?
      internal_names = nodes.map { |node| node_component_ref_from_node(node).gsub(/::/,'__') }
      sp_hash = {
        cols: COMPONENT_COLS,
        filter: [:and, 
                 [:eq, :assembly_id, assembly.id], 
                 [:oneof, :display_name, internal_names]]
      }
      Component::Instance.get_objs(assembly.model_handle(:component), sp_hash)
    end
    
    def self.iaas_type(component)
      component.get_field?(:component_type).split(COMPONENT_TYPE_DELIM).first.to_sym
    end

    def self.node_name(component)
      if component.display_name =~ /\[(.+)\]$/
        $1
      else
        fail Error, "Unexpected that display_name '#{component.display_name}' is not of form IAAS_node[NAME]"
      end
    end

  end
end
