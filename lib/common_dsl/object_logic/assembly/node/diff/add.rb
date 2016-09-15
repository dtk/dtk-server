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
module DTK; module CommonDSL 
  class ObjectLogic::Assembly
    class Node::Diff
      class Add < CommonDSL::Diff::Element::Add
        def process(result, opts = {})
          new_node = 
            case node_type
            when :node
              assembly_instance.add_node_from_diff(node_name)
            when :node_group
              fail Error "TODO: write 'assembly_instance.add_node_group_from_diff(node_name)'"
            else
              fail "Unexpected type '#{node_type}'"
            end
          add_nested_components(new_node, result)
          # dont process anything more if any errors in add_nested_components
          return if result.any_errors?

          add_node_properties_component(new_node)

          result.add_item_to_update(:assembly) # workflow updated to add a node
        end

        private 

        def node_type
          @node_type ||= @parse_object.type
        end

        def node_name
          relative_distinguished_name
        end
        
        def add_node_properties_component(node)
          image         = node_attribute(:image)
          instance_size = node_attribute(:size)
          begin 
            # TODO: hard coded to ec2_properties
            assembly_instance.add_ec2_properties_and_set_attributes(project, node, image, instance_size)
          rescue => e
            if e.respond_to?(:message)
              Diff::DiffErrors.raise_error(error_msg: e.message)
            else
              fail e
            end
          end
        end

        def add_nested_components(node, result)
           components_semantic_parse_array.each do |component|
            # TODO: need to put new node in method called below
            component_add_diff = Component::Diff::Add.new(component.qualified_key, parse_object: component, service_instance: @service_instance)
            component_add_diff.process(result)
          end 
        end

        def node_attribute(attr_name)
          @parse_object.attribute_value(attr_name)
        end

        def components_semantic_parse_hash
          @parse_object.val(:Components) || {}
        end

        def components_semantic_parse_array
          components_semantic_parse_hash.values
        end

      end
    end
  end
end; end
