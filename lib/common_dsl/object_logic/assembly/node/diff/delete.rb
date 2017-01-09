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
  class ObjectLogic::Assembly; class Node
    class Diff
      class Delete < CommonDSL::Diff::Element::Delete
        # opts can have keys
        #  :gen_object
        def initialize(qualified_key, opts = {})
          super
          @node = ret_node
        end

        def process(result, opts = {})
          if @node.is_node_group?
            fail Error "TODO: need to write delete for node groups"
          else
            delete_node(result)
          end

          result.add_item_to_update(:workflow)
          result.add_item_to_update(:assembly)
        end

        private

        def node_has_been_created?
          Node.node_has_been_created?(@node)
        end

        def ret_node
          assembly_instance.get_node_by_name?(node_name)
        end

        def node_name
          relative_distinguished_name
        end

        def delete_node(result)
          if node_has_been_created?
            # if node is created then splice into workflow explicit delete steps and remove refernces to actions on the deleted node
            # and marke the node and netsed components as 'to be deleted'
            delete_when_node_has_been_created(result)
          else
            # If node is not yet created then delete the node and its components from the assembly and the workflow
            delete_when_node_not_yet_created(result)
          end
        end

        def delete_when_node_not_yet_created(result)
          delete_nested_components(result, force_delete: true)
          delete_node_opts = result.semantic_diffs['WORKFLOWS_MODIFIED'] ? { do_not_update_task_template: true} : {}
          assembly_instance.delete_node(@node.id_handle, delete_node_opts)
        end

        def delete_nested_components(result, opts = {})
          non_node_components.each do |component|
            cmp_qualified_key = qualified_key.create_with_new_element?(:component, component[:display_name])
            component_delete_diff = Component::Diff::Delete.new(cmp_qualified_key, gen_object: component, service_instance: @service_instance)
            component_delete_diff.process(result, opts)
          end
        end

        def non_node_components
          @non_node_components ||= @node.get_components.reject { |component| ::DTK::Component::Domain::Node.is_type_of?(component) }
        end

        def delete_when_node_has_been_created(result, opts = {})
          if has_component_with_delete_action?
            delete_nested_components(result, opts)
            add_delete_node_subtask(result, opts)
          else
            add_delete_node_subtask(result, opts)
            delete_nested_components(result, opts)
          end
          @node.update_from_hash_assignments(to_be_deleted: true)
        end

        def has_component_with_delete_action?
          !!non_node_components.find { |component| Component.component_delete_action_def?(component) }
        end

        def add_delete_node_subtask(result, opts = {})
          cmp_qualified_key     = qualified_key.create_with_new_element?(:component, canonical_node_component.display_name)
          component_delete_diff = Component::Diff::Delete.new(cmp_qualified_key, gen_object: canonical_node_component, service_instance: @service_instance)

          component_delete_diff.process(result, opts)
        end

        def canonical_node_component
          @canonical_node_component ||= @node.get_components.find{ |component| ::DTK::Component::Domain::Node::Canonical.is_type_of?(component) } ||
            fail(Error, "Unexpected no node component for node '#{node_name}'")
        end

      end
    end
  end; end
end; end
