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
              # fail DTK::Error, "TODO: write 'assembly_instance.add_node_group_from_diff(node_name)'"
              fail ErrorUsage, "Adding of node groups through dsl is not supported yet."
            else
              fail DTK::Error, "Unexpected type '#{node_type}'"
            end
          
          add_nested_and_node_components(result, new_node, opts)

          unless result.any_errors?
            result.add_item_to_update(:workflow) # workflow updated to add a node
            result.add_item_to_update(:assembly)
          end
        end
        
        private 
        def add_nested_and_node_components(result, node, opts = {})
          component_module_refs = component_module_refs(opts)
          add_diff_opts = opts.merge(component_module_refs: component_module_refs)
          components_semantic_parse_array.each do |component|
            component_add_diff = Component::Diff::Add.new(component.qualified_key, parse_object: component, service_instance: @service_instance)
            # TODO: for efficiency allow a bulked up call that handles all components at same time
            component_add_diff.process(result, add_diff_opts)
          end 
          add_node_components(node, component_module_refs)
        end

        def add_node_components(node, component_module_refs)
          image         = node_attribute(:image)
          instance_size = node_attribute(:size)
          
          # TODO: hard coded to ec2_properties and ec2_node
          assembly_instance.add_ec2_node_components(project, node, image, instance_size, component_module_refs)
          # TODO: workaround if image and size are added after stage; remove when we implement attributes add and delete (now have only modify)
          attribute_set_opts = { create: true, skip_node_property_check: true, skip_image_and_size_validation: true, do_not_raise: true }
          assembly_instance.set_attributes([{ pattern: "#{node_name}/image", value: image }, { pattern: "#{node_name}/size", value: instance_size }], attribute_set_opts)
        end

        def node_type
          @node_type ||= @parse_object.type
        end
        
        def node_name
          relative_distinguished_name
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



        def add_ec2_node_component(node)
          begin
            assembly_instance.add_ec2_node_component(project, node)
          rescue => e
            if e.respond_to?(:message)
              Diff::DiffErrors.raise_error(error_msg: e.message)
            else
              fail e
            end
          end
        end




