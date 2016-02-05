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
  class Task::Status
    class HashOutput < ::Hash
      dtk_nested_require('hash_output', 'detail')

      def initialize(type, task, opts = {})
        @task = task
        replace(type: type)
        if task_fields = opts[:task_fields]
          add_task_fields?(task_fields)
          # set_duration? most be done after add_task_fields?
          set_duration?
        end
        if opts[:add_detail]
          set_nested_hash_subtasks!(self, @task, nested_opts(opts))
        end
      end

      private

      def set_duration?
        if self[:ended_at] and self[:started_at]
          self[:duration] = self[:ended_at] - self[:started_at] 
        end
      end

      def nested_opts(opts = {})
        ret = (opts.keys - [:task_field, :task_fields_nested]).inject({}) do |h, key|
          h.merge(key => opts[key])
        end
        if task_fields = opts[:task_fields_nested] || opts[:task_fields]
          ret.merge!(task_fields: task_fields)
        end
        ret
      end

      def set_nested_hash_subtasks!(hash_output, task, opts = {})
        Detail.add_details?(hash_output, task)
        if subtasks = task.subtasks?
          hash_output[:subtasks] = subtasks.map do |st| 
            subtask_hash_output = self.class.new(:subtask, st, nested_opts(opts))
            set_nested_hash_subtasks!(subtask_hash_output, st)
          end
        end
        hash_output
      end

      def add_task_fields?(keys)
        ret = self
        return ret unless @task
        
        @task.update_obj!(*keys)
        keys.each{|k|self[k] = @task[k]}
        self
      end

    end
  end
end