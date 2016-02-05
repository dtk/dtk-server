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
module DTK; class Task
  class Create
    class NodesTask < self
      def self.create_subtask(action_class, task_mh, state_change_list)
        return nil unless state_change_list and not state_change_list.empty?
        ret = nil
        all_actions = []
        if state_change_list.size == 1
          executable_action = action_class.create_from_state_change(state_change_list.first)
          all_actions << executable_action
          ret = create_new_task(task_mh, subtask_hash(action_class, executable_action))
        else
          ret = create_new_task(task_mh, concurrent_subtask(action_class))
          state_change_list.each do |sc|
            executable_action = action_class.create_from_state_change(sc)
            all_actions << executable_action
            ret.add_subtask_from_hash(subtask_hash(action_class, executable_action))
          end
        end
        attr_mh = task_mh.createMH(:attribute)
        action_class.add_attributes!(attr_mh, all_actions)
        ret
      end

      private

      def self.concurrent_subtask(action_class)
        {
          display_name: action_class.stage_display_name(),
          temporal_order: 'concurrent'
        }
      end

      def self.subtask_hash(action_class, executable_action)
        {
          display_name: action_class.task_display_name(),
          executable_action: executable_action
        }
      end
    end
  end
end; end