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
        else # subtasks is nil  means that task is leaf task
          LeafTask.add_details!(ret_nested_hash, task)
        end
        ret_nested_hash
      end

      class LeafTask
        def initialize(ret_nested_hash, leaf_task)
          @ret_nested_hash = ret_nested_hash
          @leaf_task       = leaf_task
        end

        def self.add_details!(ret_nested_hash, leaf_task)
          new(ret_nested_hash, leaf_task).add_details!
        end
        def add_details!
          add_components_and_actions!
          set?(:action_results, action_results())
          # set(:errors, errors())
          @ret_nested_hash
        end

        private
        def add_components_and_actions!
          # TODO: stub
        end

        def action_results
          if action_results = @leaf_task[:action_results]
            action_results
          end
        end

        def set?(key, value)
          unless value.nil?
            @ret_nested_hash[key] = value
          end
        end
      end
    end
  end
end; end; end

=begin
"status"=>0,
          "stdout"=>
           "15/07/15 22:28:29 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable\n\r[Stage 0:>                                                          (0 + 0) / 2]\r[Stage 0:>                                                          (0 + 1) / 2]\r                                                                                \rPi is roughly 3.14468\n",
          "stderr"=>"",
          "description"=>
           "su spark -c \"cd /usr/lib/spark && ./bin/spark-submit --class org.apache.spark.examples.SparkPi /usr/lib/spark/lib/spark-examples-1.3.1-hadoop2.4.0.jar\"  2>&1 (syscall)",
          "child_task"
=end
