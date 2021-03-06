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
        #  TODO: ...
        def delete_explicit_action?(action, action_list, opts = {})
          match_opts = (action.is_a?(Action::WithMethod) ? { class: Action::WithMethod } : {})
          if indexed_action = action_list.find { |a| a.match_action?(action, match_opts) }
            if action_match = includes_action?(indexed_action)
              delete_action?(action_match, indexed_action, opts)
            end
          end
        end

        def delete_actions_on_node?(node, action_list)
          # delete if it exists canonical node delete action, which servres to update the spliced in delete subtask 
          if delete_action = canonical_node_component_delete_action?(node)
            delete_explicit_action?(delete_action, action_list)
          else
            Log.error("Unexpected that node '#{node.display_name}' does not have a canonical_node_component")
          end
          delete_components_on_node!(node)
        end

        private
          
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

        def delete_components_on_node!(node)
          each_internode_stage do |internode_stage, internode_stage_index|
            if :empty == internode_stage.delete_components_on_node!(node)
              delete_internode_stage!(internode_stage_index)
              :empty if empty?
            end
          end
        end

        def delete_internode_stage!(internode_stage_index)
          delete_at(internode_stage_index - 1)
        end

        def canonical_node_component_delete_action?(node)
          if canonical_node_component = canonical_node_component?(node)
            delete_action_def = CommonDSL::ObjectLogic::Assembly::Component.component_delete_action_def?(canonical_node_component)
            Action.create(canonical_node_component.add_title_field?().merge(node: node), action_def: delete_action_def)
          end
        end

        def canonical_node_component?(node)
         sp_hash = {
           #:only_one_per_node,:ref are put in for info needed when getting title
           cols: [:id, :display_name, :node_node_id, :only_one_per_node, :ref],
            filter: [:eq, :node_node_id, node.id]
          }
          Component::Instance.get_objs(node.model_handle(:component), sp_hash).find do |component|
            Component::Domain::Node::Canonical.is_type_of?(component)
          end
        end

      end
    end
  end
end
