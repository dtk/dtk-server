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
  class ObjectLogic::Assembly::Component::Diff::Delete::TaskTemplate
    module SpliceInDeleteAction
      module Mixin
        def splice_in_delete_action!(serialized_content)
          delete_subtask = find_or_add_delete_subtask!(serialized_content)
          add_delete_action_in_subtask!(delete_subtask)
          serialized_content
        end

        private

        module HashKey
          include Parse::CanonicalInput::HashKey
        end

        def find_or_add_delete_subtask!(serialized_content)
          unless top_subtasks = serialized_content[HashKey::Subtasks]
            raise_error_unexpecetd_form("Unexpected that term does not have :#{HashKey::Subtasks} key", serialized_content)
          end

          unless ret = top_subtasks.find { |subtask| subtask[HashKey::Name] ==  delete_subtask_name }
            # if delete subtask is top task - return top task and use it as delete subtask
            if serialized_content[HashKey::Import] && serialized_content[HashKey::Flatten]
              ret = serialized_content
            else
              ret = empty_delete_subtask
              top_subtasks.insert(0, ret)
            end
          end

          ret
        end

        DELETE_SUBTASK_LOCATION = '.workflow/dtk.workflow.delete_subtask_for_create.yaml'
        def empty_delete_subtask
          {
            HashKey::Name          => delete_subtask_name,
            HashKey::Import        => DELETE_SUBTASK_LOCATION,
            HashKey::Flatten       => true,
            HashKey::SubtaskOrder  => 'sequential',
            HashKey::Subtasks      => []
          }
        end

        def add_delete_action_in_subtask!(delete_subtask)
          delete_subtasks = delete_subtask[HashKey::Subtasks]
          delete_subtasks << delete_action_subtask
          delete_subtasks
        end

        
        def delete_action_subtask
          { 
            HashKey::Name   => "Delete #{component_term}",
            HashKey::Node   => @node.display_name,
            HashKey::Action => delete_action_term 
          } 
        end

        DELETE_SUBTASK_NAME = 'delete subtask'
        def delete_subtask_name
          DELETE_SUBTASK_NAME
        end

        def component_term
          component_type = Component.component_type_print_form(@component[:component_type])
          title          = @component.title?
          title ? ComponentTitle.print_form_with_title(component_type, title) : component_type
        end

        ACTION_DELIM = '.'
        def delete_action_term
          "#{component_term}#{ACTION_DELIM}delete"
        end

        def raise_error_unexpecetd_form(err_msg, content)
          fail Error, "#{err_msg}: #{content.inspect}"
        end

      end
    end
  end
end; end
