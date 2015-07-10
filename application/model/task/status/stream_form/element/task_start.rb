module DTK; class Task; class Status
  class StreamForm; class Element
    class TaskStart < self
      def initialize(task)
        super(:task_start,task)
      end

      def hash_form
        pp @task
        task_structure = @task.get_hierarchical_structure()
        leaf_subtasks = task_structure.get_leaf_subtasks()
        Log.info("stub for Status::StreamForm.status")
        
        status_opts = Hash.new.merge(:no_components => false, :no_attributes => true)
        status_opts.merge!(:summarize_node_groups => true)
        t = TableForm.status(task_structure,status_opts)
        pp t
        super()
      end
    
    end
  end; end
end; end; end
