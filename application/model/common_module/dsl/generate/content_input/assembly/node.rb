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
module DTK; module CommonModule::DSL::Generate
  class ContentInput 
    class Assembly
      class Node < ContentInput::Hash
        require_relative('node/attribute')

        def self.generate_content_input(assembly_instance)
          ret = ContentInput::Array.new
          get_augmented_nodes(assembly_instance).each { |aug_node| ret << new.generate_content_input!(aug_node) }
          ret
        end
        
        def generate_content_input!(aug_node)
          aug_components = aug_node[:components] || []
          attributes = aug_node[:attributes] || []
          # :is_assembly_wide_node just used intentall; so not using 'set' method
          self[:is_assembly_wide_node] = true if aug_node.is_assembly_wide_node?
          
          set(:Name, aug_node.display_name)
          set?(:Attributes, Attribute.generate_content_input?(:node, attributes)) unless attributes.empty?
          set(:Components, Component.generate_content_input(aug_components)) unless aug_components.empty?
          self
        end

        private
        
        def self.get_augmented_nodes(assembly_instance)
          ndx_nodes = assembly_instance.get_nodes.inject({}) { |h, r| h.merge(r.id => r) }
          add_node_level_attributes!(ndx_nodes)
          add_augmented_components!(ndx_nodes)
          ndx_nodes.values
        end
        
        def self.add_node_level_attributes!(ndx_nodes)
          node_idhs = ndx_nodes.values.reject { |node| node.is_assembly_wide_node? }.map(&:id_handle)
          unless node_idhs.empty?
            DTK::Node.get_node_level_assembly_template_attributes(node_idhs).each do |r|
              node_id = r[:node_node_id]
              (ndx_nodes[node_id][:attributes] ||= []) << r
            end
          end
        end

        def self.add_augmented_components!(ndx_nodes)
          DTK::Node::Instance.add_augmented_components!(ndx_nodes)
        end
        
      end
    end
  end
end; end

