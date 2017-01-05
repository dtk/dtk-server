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
  class Task::Template
    class Content
      module DeleteMixin
        # if action is explicitly included in task template then delete the action from this object and return updated object
        # else return nil
        def delete_explicit_action?(action, action_list, opts = {})
          opts.merge!(class: Action::WithMethod) if action.is_a?(Action::WithMethod)
          if indexed_action = action_list.find { |a| a.match_action?(action, opts) }
            # TODO: DTK-2732: validate: think this will be executed on cleanup task, we need to delete .delete action from workflow
            # I put in this opts.merge!(class: Action::WithMethod) if action.is_a?(Action::WithMethod) above and also
            # this part below because in action_list above it will not match component .delete action but only action for creating component
            # on config node
            # So I put this part below which will match component .delete action and delete it, instead of deleting component create action
            #
            if action.is_a?(Action::WithMethod)
              indexed_action = action if indexed_action.component_type.eql?("ec2::node[#{indexed_action.node_name}]") || opts[:remove_delete_action]
            end
            if action_match = includes_action?(indexed_action)
              # TODO: DTK-2732: look at whether when it is not in_multinode_stage whether we should still delete if this component is only instance
              # that matches this step. 
              # note: in_multinode_stage is somehwta in misnomer in that it can be true when step only refers to assembly wide
              if action_match.is_assembly_wide? or !action_match.in_multinode_stage
                delete_action!(action_match)
                self
              end
            end
          end
        end
        
        private
        
        
        def delete_action!(action_match)
          internode_stage_index = action_match.internode_stage_index
          if :empty == internode_stage(internode_stage_index).delete_action!(action_match)
            delete_internode_stage!(internode_stage_index)
            :empty if empty?
          end
        end
        
      end
    end
  end
end
