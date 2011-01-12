module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow
      def execute_implementation()
        results = Hash.new
        #TODO: as temp move hardwiring to look for specfic patterns
        if @task.elements.empty?
          executable_action = @task[:executable_action]
          if executable_action.kind_of?(TaskAction::ConfigNode)
            results[executable_action[:id]] = self.class.create_or_execute_on_node(nil,executable_action)
          elsif executable_action.kind_of?(TaskAction::CreateNode)
            results[executable_action[:id]] = self.class.create_or_execute_on_node(executable_action,nil)
          end
          return results
        end
        create_node,config_node = pattern_node_create_and_config()
        if create_node and config_node
          return self.class.create_or_execute_on_node(create_node,config_node)
        end

        if @task[:temporal_order].to_sym == :sequential
          @task.elements.each do |sub_task|
            sub_task_results = Simple.new(sub_task).execute_implementation() 
            sub_task_results.merge!(sub_task_results)
          end
        elsif @task[:temporal_order].to_sym == :concurrent
          lock = Mutex.new
          threads = @task.elements.map do |sub_task|
            Thread.new do 
              sub_task_result = Simple.new(sub_task).execute_implementation()
              lock.synchronize do 
                sub_task_results.merge!(sub_task_results)
              end
            end
          end
          threads.each{|t| t.join}
        end
        results
      end
     private 

      def initialize(task)
        @task = task
      end

      def pattern_node_create_and_config()
        return nil unless @task[:temporal_order].to_sym == :sequential
        return nil unless @task.elements and @task.elements.size == 2
        return nil unless @task.elements[0].kind_of?(TaskAction::CreateNode)
        return nil unless @task.elements[1].kind_of?(TaskAction::ConfigNode)
        @task.elements
      end

=begin
      def execute_implementation()
        results = Hash.new
        #TODO: assuming that elements are node_actions
        if @type == :sequential
          @elements.each do |node_actions|
            results[node_actions[:id]] = self.class.create_or_execute_on_node(node_actions)
          end
        elsif @type == :concurrent
          threads = @elements.map do |node_actions| 
            Thread.new do 
              result = create_or_execute_on_node(node_actions)
              @lock.synchronize do 
                results[node_actions[:id]] = result
              end
            end
          end
          threads.each{|t| t.join}
        end
        results
      end
     private 
      def initialize(ordered_actions)
        @type = ordered_actions.is_concurrent?() ? :concurrent : :sequential
        @elements = ordered_actions.is_single_state_change?() ? [ordered_actions.single_state_change()] : ordered_actions.elements
        @lock = Mutex.new
        #TODO: put in max threads
     end
=end
    end
  end
end
