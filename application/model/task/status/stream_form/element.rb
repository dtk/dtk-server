module DTK; class Task; class Status
  class StreamForm
    class Element 
      def initialize(type,task)
        @type = type
        @task = task
      end
      private :initialize

      def  hash_form()
        {
          :type       => @type,
          :started_at => @task.get_field?(:started_at)
        }
      end

      class TaskStart < self
        def initialize(task)
          super(:task_start,task)
        end
        def hash_form()
          pp @task
          Log.info("stub for Status::StreamForm.status")
          task_structure = @task.get_hierarchical_structure()
          status_opts = Hash.new.merge(:no_components => false, :no_attributes => true)
          status_opts.merge!(:summarize_node_groups => true)
          t = TableForm.status(task_structure,status_opts)
          pp t
          File.open('/tmp/t5.rb','w'){|f|PP.pp(t,f)}
          super()
        end

      end
    end
  end
end; end; end
