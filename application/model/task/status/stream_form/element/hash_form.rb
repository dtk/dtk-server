module DTK; class Task::Status::StreamForm
  class Element
    class HashForm < ::Hash
      def initialize(element)
        @task = element.task
        
        replace(type: element.type)
        add_task_fields?(:started_at, :display_name)
      end
      
      def add_task_fields?(*keys)
        ret = self
        return ret unless @task
        
        @task.update_obj!(*keys)
        keys.each{|k|self[k] = @task[k]}
        self
      end
    end
  end
end; end


