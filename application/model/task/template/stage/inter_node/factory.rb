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
    class Stage
      class InterNode
        class Factory
          def initialize(action_list, temporal_constraints)
            @action_list          = action_list
            @temporal_constraints = temporal_constraints
          end
          
          def create(stage_action_indexes, name = nil)
            # first break each state into unordered list per node
            ret = InterNode.new(name)
            stage_action_indexes.each do |i|
              action = self.action_list.index(i)
              (ret[action.node_id] ||= IntraNode::Unordered.new()) << action
            end
            
            intra_node_proc = IntraNode::Processor.new(self.temporal_constraints)
            ret.each_node_id { |node_id| ret[node_id] = intra_node_proc.process(ret[node_id]) }
            ret
          end
          
          protected
          
          attr_reader :action_list, :temporal_constraints
          
          module StageName
            include Serialization
            DefaultNameProc = lambda do |internode_stage, index, is_single_stage|
              if name = StageName.canonical_name?(internode_stage)
                name
              else
                is_single_stage ? 'stage' : "stage_#{index}"
              end
            end
            
            DefaultNodeGroupNameProc = lambda do |internode_stage, index, is_single_stage|
              if name = StageName.canonical_name?(internode_stage)
                name
              else
                ret = 'node_group_components'
                is_single_stage ? ret : (ret + "_stage_#{index}")
              end
            end
            
            def self.canonical_name?(internode_stage)
              serialization_form = internode_stage.serialization_form
              if components = serialization_form[Constant::Components]
                if components.size == 1
                  "Component #{components.first}"
                end
              end
            end

          end
        end
      end
    end
  end
end
