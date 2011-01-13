module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow

      def execute_implementation()
        @task.update(:status => "executing")
        executable_action = @task[:executable_action]
        if executable_action
          begin 
            result_hash = CommandAndControl.execute_task_action(executable_action)
            update_hash = {
              :status => "succeeded",
              :result => TaskAction::Result::Succeeded.new(result_hash)
            }
            @task.update(update_hash)
            executable_action.update_state(:completed)  #this send pending changes' states
            propagate_output_vars(result_hash)
            debug_pp [:task_succeeded,@task.id,result_hash]
                         
           rescue CommandAndControl::Error => e
            update_hash = {
              :status => "failed",
              :result => TaskAction::Result::Failed.new(e)
            }
            @task.update(update_hash)
            debug_pp [:task_failed,@task.id,e]
           rescue Exception => e
            update_hash = {
              :status => "failed",
              :result => TaskAction::Result::Failed.new(CommandAndControl::Error.new)
            }
            @task.update(update_hash)
            debug_pp [:task_failed_internal_error,@task.id,e,e.backtrace]
          end
        elsif @task[:temporal_order].to_sym == :sequential
          @task.elements.each do |sub_task|
            #TODO: execute_implementation() should send trap here depending on @task[:action_on_failure] == "abort"
            Simple.new(sub_task).execute_implementation() 
          end
        elsif @task[:temporal_order].to_sym == :concurrent
          lock = Mutex.new
          threads = @task.elements.map do |sub_task|
            Thread.new do 
              Simple.new(sub_task).execute_implementation()
            end
          end
          threads.each{|t| t.join}
        end
      end
     private
      def propagate_output_vars(result_hash)
        @task.task_param_inputs.each do |param_link|
          unless param_link.output_task and param_link[:input_var_path] and param_link[:output_var_path]
            Log.error("skipping param link because missing param")
            next
          end
          val = param_link[:input_var_path].inject(result_hash){|r,key|r[key]||{}}
          pointer = param_link.output_task
          output_path = param_link[:output_var_path].inject([]){|r,x| r << x} 
          last_key = output_path.pop
          output_path.each do |k|
            pointer[k] ||= Hash.new
            pointer = pointer[k]
          end
          pointer[last_key] = val
        end
      end

      def debug_pp(x)
        @@debug_lock.synchronize{pp x}
      end
      @@debug_lock = Mutex.new
=begin

      def execute_implementation()
        results = Hash.new
        #TODO: as temp move hardwiring to look for specfic patterns
        if @task.elements.empty?
          executable_action = @task[:executable_action]
          if executable_action.kind_of?(TaskAction::ConfigNode)
            results[executable_action.id] = self.class.create_or_execute_on_node(nil,executable_action)
          elsif executable_action.kind_of?(TaskAction::CreateNode)
            results[executable_action.id] = self.class.create_or_execute_on_node(executable_action,nil)
          end
          return results
        end
        create_node,config_node = pattern_node_create_and_config()
        if create_node and config_node
          results[create_node.id] = self.class.create_or_execute_on_node(create_node,config_node)
          return results
        end

        if @task[:temporal_order].to_sym == :sequential
          @task.elements.each do |sub_task|
            sub_task_results = Simple.new(sub_task).execute_implementation() 
            results.merge!(sub_task_results)
          end
        elsif @task[:temporal_order].to_sym == :concurrent
          lock = Mutex.new
          threads = @task.elements.map do |sub_task|
            Thread.new do 
              sub_task_result = Simple.new(sub_task).execute_implementation()
              lock.synchronize do 
                results.merge!(sub_task_results)
              end
            end
          end
          threads.each{|t| t.join}
        end
        results
      end
=end
     private 

      def initialize(task)
        @task = task
      end
=begin
      def pattern_node_create_and_config()
        return nil unless @task[:temporal_order].to_sym == :sequential
        return nil unless @task.elements and @task.elements.size == 2
        return nil unless @task.elements[0].kind_of?(TaskAction::CreateNode)
        return nil unless @task.elements[1].kind_of?(TaskAction::ConfigNode)
        @task.elements
      end
=end
    end
  end
end
