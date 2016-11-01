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
    class Component::Diff
      class Delete < CommonDSL::Diff::Element::Delete
        include Mixin

        # opts can have keys:
        #   :force_delete - delete without adding delete actions
        def process(result, opts = {})
          augmented_cmps = assembly_instance.get_augmented_components(Opts.new(filter_component: component_name))
          if augmented_cmps.empty?
            result.add_error_msg("Component '#{qualified_key.print_form}' does not match any components")
          else
            node          = parent_node? || assembly_instance.has_assembly_wide_node?
            matching_cmps = augmented_cmps.select{|cmp| cmp[:node][:display_name] == node[:display_name]}

            if matching_cmps.size > 1
              result.add_error_msg("Unexpected that component name '#{qualified_key.print_form}' match multiple components")
            else
              component_instance = DTK::Component::Instance.create_from_component(matching_cmps.first)
              delete_component(component_instance, node, force_delete: opts[:force_delete])
              result.add_item_to_update(:assembly)
              result.add_item_to_update(:workflow)
            end
          end
        end

        private

        # opts can have keys:
        #   :force_delete
        def delete_component(component, node, opts = {})
          insert_explict_delete_action_in_task_template?(component, node, opts)
          # assembly_instance.delete_component can update task template by removing step that has componentt 
          assembly_instance.delete_component(component.id_handle, node.id)
        end

        # opts can have keys:
        #   :force_delete
        def insert_explict_delete_action_in_task_template?(component, node, opts = {})
          return  if opts[:force_delete]
          if delete_action_def = component_delete_action_def?(component)
            # TODO: DTK-2732: Only run delete action on assembly level node if it has been converged
            # Best way to treat this is by keeping component info on what has been converged
            if node.is_assembly_wide_node? or  node.get_admin_op_status != 'pending'
              insert_explict_delete_action_in_task_template(component, node, delete_action_def)
            end
          end
        end

        def insert_explict_delete_action_in_task_template(component, node, delete_action_def)
          unless component.get_field?(:to_be_deleted)
            add_delete_action_opts = { 
              action_def: delete_action_def,
              skip_if_not_found: true, 
              insert_strategy: :insert_at_start_in_subtask,
              # TODO: DTK-2680; Aldin: see if :add_delete_action still needed after we make the other updates
              add_delete_action: true
            }
            if component_title = component.title?
              add_delete_action_opts[:component_title] = component_title
            end
            Task::Template::ConfigComponents.update_when_added_component_or_action?(assembly_instance, node, component, add_delete_action_opts)
            component.update_from_hash_assignments(to_be_deleted: true)        
          end
        end

        def component_delete_action_def?(component)
          DTK::Component::Instance.create_from_component(component).get_action_def?('delete')
        end
      end
    end
  end
end; end
