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
  module WorkflowAdapter
    class BulkCreate
      def self.create_nodes?(subtasks, context, parent)
        unless subtasks.empty?
          if subtasks.find { |subtask| should_be_bulked?(subtask) }
            if subtasks.find { |subtask| ! should_be_bulked?(subtask) }
              # TODO: DTK-2471: enhance
              fail ErrorUsage.new("Not Handling create nodes with mixed BOSH and non-BOSH nodes")
            end
            compute_process_body_reformatted(subtasks, context, parent)
          end
        end
      end

      def self.create_node?(task, context, parent)
        create_nodes?([task], context, parent)
      end
      
      private
      
      def self.should_be_bulked?(task)
        if executable_action = task[:executable_action]
          if executable_action.kind_of?(Task::Action::CreateNode) and ! executable_action.kind_of?(Task::Action::PowerOnNode)
            if external_ref = (executable_action[:node] || {})[:external_ref]
              external_ref[:type] == 'bosh_instance'
            end
          end
        end
      end
      
      def self.compute_process_body_reformatted(subtasks, context, parent)
        # mark last subtask to initiate create nodes
        mark_initiate!(subtasks)
        queue_tasks = subtasks.map do |task|
          parent.participant_executable_action(:create_node, task, context, task_start: true)
        end
        detect_created_tasks = subtasks.map do |task|
          parent.participant_executable_action(:detect_created_node_is_ready, task, context, task_type: 'post', task_end: true)
        end
        # TODO: double check this logic; but since the detect_created_tasks doing same thing; we can make them sequential and then
        # have first one cache results for rest
        parent.sequence(queue_tasks + detect_created_tasks)
      end
      
      def self.mark_initiate!(subtasks)
        last_task = subtasks.last
        last_task[:executable_action].merge!(initiate_create_nodes: true)
      end
    end
  end
end

      
