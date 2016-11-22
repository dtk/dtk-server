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
        require_relative('delete/task_template')

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
              component = DTK::Component::Instance.create_from_component(matching_cmps.first)

              # no op if to_be_deleted is set since this is peristent setting we use to detect whether the task update has been done already
              return if component.get_field?(:to_be_deleted)

              # Task template processing consists of
              # - removes any step that mentions the component
              # - if delete action defined for component then puts an explicit delete action in workflow
              task_template_processor = TaskTemplate.new(assembly_instance, component, node)

              if opts[:force_delete] || node.get_admin_op_status.eql?('pending') || !task_template_processor.component_delete_action_def?
                # if workflow is modified by user, we do not want to change it when deleting component
                delete_cmp_opts = result.semantic_diffs['WORKFLOWS_MODIFIED'] ? { do_not_update_task_template: true } : {}
                assembly_instance.delete_component(component.id_handle, node[:id], delete_cmp_opts)
              else
                task_template_processor.insert_explict_delete_action?(force_delete: opts[:force_delete])
                task_template_processor.remove_component_actions? unless component[:component_type].eql?('ec2__node')

                component.update_from_hash_assignments(to_be_deleted: true)
              end

              result.add_item_to_update(:assembly)
              result.add_item_to_update(:workflow)
            end
          end
        end

      end
    end
  end
end; end
