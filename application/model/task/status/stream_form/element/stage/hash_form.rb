module DTK; class Task::Status::StreamForm; class Element
  class Stage
    class HashForm < Element::HashForm
      def initialize(type, task, opts = {})
        super(type, task)
        add_task_fields?(:status, :ended_at, :position)
        unless opts[:donot_add_detail]
          add_nested_detail!
        end
      end

      private

      def self.create_nested_hash_form(task)
        new(:subtask, task, donot_add_detail: true)
      end

      def add_nested_detail!
        set_nested_hash_subtasks!(self, @task)
      end

      def set_nested_hash_subtasks!(ret_nested_hash,task)
        if subtasks = task.subtasks?
          ret_nested_hash[:subtasks] = subtasks.map do |st| 
            set_nested_hash_subtasks!(self.class.create_nested_hash_form(st), st) 
          end
        else
          # means that task is leaf task
          add_leaf_task_details!(ret_nested_hash, task)
        end
        ret_nested_hash
      end

      def add_leaf_task_details!(ret_nested_hash, leaf_task)
        if action_results = leaf_task[:action_results]
          ret_nested_hash[:action_results] ||= []
          ret_nested_hash[:action_results] += action_results
        end
        ret_nested_hash
      end

    end
  end
end; end; end


