class DTK::Task; class Status::StreamForm; class Element
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
pp [:lllllllllllllllllllllintermediate,task.keys]
          ret_nested_hash[:subtasks] = subtasks.map do |st| 
            set_nested_hash_subtasks!(self.class.create_nested_hash_form(st), st) 
          end
        else # subtasks is nil  means that task is leaf task
          Status::LeafTask.add_details!(ret_nested_hash, task)
        end
        ret_nested_hash
      end

    end
  end
end; end; end
