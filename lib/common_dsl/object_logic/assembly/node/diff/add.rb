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
  class ObjectLogic::Assembly::Node
    class Diff
      class Add < CommonDSL::Diff::Element::Add
        def process
          new_node = 
            case node_type
            when :node
              assembly_instance.add_node_from_diff(node_name)
            when :node_group
              fail Error "TODO: write 'assembly_instance.add_node_group_from_diff(node_name)'"
            else
              fail "Unexpected type '#{node_type}'"
            end
          add_node_properties_component(new_node)
          add_nested_components(new_node)
          nil
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
          pp(image: image, instance_size: instance_size)
          # TODO: hard coded to ec2_properties
          assembly_instance.add_ec2_properties_and_set_attributes(project, node, image, instance_size)
        end

        # TODO: move so that can create component add components for each and bulk of this code there so
        # can reuse code if added if under node or new top level
        def add_nested_components(node)
          # stub
          pp [:add_nested_components, :components, components_indexed_by_names]
          components.each do |component|
            matching_aug_cmp_templates = ::DTK::Component::Template.find_matching_component_templates(assembly_instance, component.name) 
            pp [:matching_aug_cmp_templates, component.name, matching_aug_cmp_templates]
            unless matching_aug_cmp_templates.size == 1
              fail Error, "TODO: DTK-2650: put in error messages to indicate that no or ambiguous module match found"
            end
            aug_cmp_template = matching_aug_cmp_templates.first
            # TODO: use this and node to add component to node
          end 
        end

        def node_attribute(attr_name)
          @parse_object.attribute_value(attr_name)
        end

        def components_indexed_by_names
          @parse_object.val(:Components) || {}
        end
        def components
          components_indexed_by_names.values
        end

      end
    end
  end
end; end
