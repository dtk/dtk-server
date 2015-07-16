module DTK
  class Task::Status
    class HashOutput < ::Hash
      dtk_nested_require('hash_output', 'detail')

      def initialize(type, task, opts = {})
        @task = task
        replace(type: type)
        if task_fields = opts[:task_fields]
          add_task_fields?(task_fields)
        end
        if opts[:add_detail]
          set_nested_hash_subtasks!(self, @task, nested_opts(opts))
        end
      end

      private

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


