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
        # opts can have keys:
        #   :remove_delete_action  
        #  TODO: ...
        def delete_explicit_action?(action, action_list, opts = {})
          # TODO: cleanup so dont use merge; firs make sure not used outside this context
          opts.merge!(class: Action::WithMethod) if action.is_a?(Action::WithMethod) 
          if indexed_action = indexed_action?(action, action_list, Aux.hash_subset(opts, [:remove_delete_action]))
            if action_match = includes_action?(indexed_action)
              delete_action?(action_match, indexed_action, opts)
            end
          end
        end

        private
          
        def indexed_action?(action, action_list, opts = {})
          if indexed_action = action_list.find { |a| a.match_action?(action, opts) }
            # TODO: DTK-2732: validate: this will be executed on cleanup task, we need to delete .delete action from workflow
            # and cleanup
            # also cleanup up refernce "ec2::node ...
            if action.is_a?(Action::WithMethod) and 
                (indexed_action.component_type.eql?("ec2::node[#{indexed_action.node_name}]") || opts[:remove_delete_action]) 
              indexed_action = action 
            end
            indexed_action
          end
        end
        
        def delete_action?(action_match, indexed_action, opts = {})
          # TODO: DTK-2732: look at whether when it is not in_multinode_stage whether we should still delete if this component is only instance
          # that matches this step. 
          # note: 'in_multinode_stage' is somewhat in misnomer in that it can be true when step only refers to assembly wide
          if action_match.is_assembly_wide? or !action_match.in_multinode_stage
            delete_action!(action_match, indexed_action, opts)
            self
          end
        end
        
        def delete_action!(action_match, indexed_action, opts = {})
          internode_stage_index = action_match.internode_stage_index
          internode_stage       = internode_stage(internode_stage_index)
          
          if :empty == internode_stage.delete_action!(action_match)
            delete_internode_stage!(internode_stage_index)
            :empty if empty?
          end          
        end

        def delete_internode_stage!(internode_stage_index)
          delete_at(internode_stage_index - 1)
        end
        
      end
    end
  end
end
