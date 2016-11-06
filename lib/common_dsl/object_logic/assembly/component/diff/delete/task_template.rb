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
  module CommonDSL 
    class ObjectLogic::Assembly::Component::Diff::Delete
      # methods for updating the task template
      class TaskTemplate
        require_relative('task_template/splice_in_delete_action')
        include SpliceInDeleteAction::Mixin

        def initialize(assembly_instance, component, node)
          @assembly_instance = assembly_instance
          @component         = component
          @node              = node
        end

        # opts can have keys
        #   :force_delete
        def insert_explict_delete_action?(opts = {})
          return if opts[:force_delete]
          if component_delete_action_def?
            # TODO: DTK-2732: Only run delete action on assembly level node if it has been converged
            # Best way to treat this is by keeping component info on what has been converged
            if @node.is_assembly_wide_node? or  @node.get_admin_op_status != 'pending'
              insert_explict_delete_action
            end
          end
        end

        def remove_component_actions?
          Task::Template::ConfigComponents.update_when_deleted_component?(@assembly_instance, @node, @component) 
        end


        # TODO: DTK-2732: Currently, rather than inserting in a subtask working in refied form using the same method that is 
        #       used in edit-action (edit-workflow) which takes in a modified workflow as input; 
        #       want to see if we shoudl switch to more semantic way of updating
        def insert_explict_delete_action
          serialized_content = Task::Template::ConfigComponents.get_serialized_template_content(@assembly_instance)

          # TODO: DTK-2689: Rich: I've added this to avoid raise of exception in
          # dtk-server/lib/common_dsl/object_logic/assembly/component/diff/delete/task_template/splice_in_delete_action.rb:44
          serialized_content = { subtasks: [serialized_content] } unless serialized_content[:subtasks]

          splice_in_delete_action!(serialized_content)
          pp ["DEBUG: task template after splice_in_delete_action", serialized_content]
          Task::Template.update_from_serialized_content?(@assembly_instance.id_handle, serialized_content)
        end
=begin
        ## TODO: DTK-2680: Aldin
        #   Keeping around old so we can see whether after removibgf it we can remove thiongs in functions it callss that were just needed by it
        def insert_explict_delete_action_aux
          add_delete_action_opts = { 
            action_def: component_delete_action_def?,
            skip_if_not_found: true, 
            insert_strategy: :insert_at_start_in_subtask,
            add_delete_action: true
          }
          if component_title = @component.title?
            add_delete_action_opts[:component_title] = component_title
          end
          Task::Template::ConfigComponents.update_when_added_component_or_action?(@assembly_instance, @node, @component, add_delete_action_opts)
=end

        private
        
        def component_delete_action_def?
          DTK::Component::Instance.create_from_component(@component).get_action_def?('delete')
        end

      end
    end
  end
end

