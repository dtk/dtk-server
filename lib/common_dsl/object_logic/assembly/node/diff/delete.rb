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
      class Delete < CommonDSL::Diff::Element::Delete
        def process(result, opts = {})
          node = assembly_instance.get_node_by_name?(node_name)

          if node.is_node_group?
            fail Error "TODO: need to write delete for node groups"
          else
            delete_node(node, result)
          end

          result.add_item_to_update(:workflow)
        end

        private

        def node_name
          relative_distinguished_name
        end

        def delete_node(node, result)
          if node.get_admin_op_status == 'pending'
            delete_node_and_nested_components(node, result, force_delete: true)
          else
            generate_delete_node_workflow(node, result)
          end
        end

        def delete_node_and_nested_components(node, result, opts = {})
          delete_nested_components(node, result, opts)
          assembly_instance.delete_node(node.id_handle, destroy_nodes: true)
        end

        def delete_nested_components(node, result, opts = {})
          node_components = node.get_components.reject{ |cmp| IgnoreComponents.include?(cmp[:component_type]) }
          node_components.each do |component|
            cmp_qualified_key = qualified_key.create_with_new_element?(:component, component[:display_name])
            component_delete_diff = ObjectLogic::Assembly::Component::Diff::Delete.new(cmp_qualified_key, gen_object: component, service_instance: @service_instance)
            component_delete_diff.process(result, opts)
          end
        end
        IgnoreComponents = ['ec2__properties', 'ec2__node']

        def generate_delete_node_workflow(node, result, opts = {})
          delete_nested_components(node, result, opts)
          ec2_node_component = Component::Template.get_augmented_component_template?(assembly_instance, 'ec2::node', namespace: 'aws', use_base_template: true)
          new_component_idh = assembly_instance.add_component(node.id_handle, ec2_node_component, node[:display_name], splice_in_delete_action: true)
          node.update_from_hash_assignments(to_be_deleted: true)
        end
      end
    end
  end
end; end
