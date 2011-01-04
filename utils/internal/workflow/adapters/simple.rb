module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow
      def execute()
        results = Hash.new
        #TODO: assuming that elements are node_actions
        if @type == :sequential
          @elements.each do |node_actions|
            results[node_actions[:id]] = execute_on_node(node_actions)
          end
        elsif @type == :concurrent
          threads = @elements.map do |node_actions| 
            Thread.new do 
              result = execute_on_node(node_actions)
              @lock.synchronize do 
                results[node_actions[:id]] = result
              end
            end
          end
          threads.each{|t| t.join}
        end
        pp [:results, results]
      end
     private 
      def execute_on_node(node_actions)
        config_agent = ConfigAgent.load(node_actions.config_agent_type)
        begin
          CommandAndControl::Adapter.dispatch_to_client(node_actions,config_agent)
         rescue Exception => e
          Log.error("error in workflow execute_on_node: #{e.inspect}")
          {:status => :failed,
            :node_name => config_agent.node_name(node_actions[:node]), 
            :error => e
          }
        end
      end

      def initialize(ordered_actions)
        @type = ordered_actions.is_concurrent?() ? :concurrent : :sequential
        @elements = ordered_actions.is_single_action?() ? [ordered_actions.single_action()] : ordered_actions.elements
        @lock = Mutex.new
        #TODO: put in max threads
     end
    end
  end
end
