module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow
      def execute()
        results = Hash.new
        #TODO: assuming that elements are node_actions
        if @type == :sequential
          @elements.each{|node_actions| results << execute_on_node(node_actions)}
        elsif @type == :concurrent
          threads = @elements.map do |node_actions| 
            Thread.new do 
              result = execute_on_node(node_actions)
              @lock.synchronize{results[node_actions[:id]] = result}
            end
          end
          threads.each{|t| t.join}
        end
        pp [:results, results]
      end
     private 
      def execute_on_node(node_actions)
        begin
          cac = CommandAndControl.create()
          data = cac.dispatch_to_client(node_actions)
        rescue Exception => e
          Log.error("error in workflow execute_on_node: #{e.inspect}")
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
