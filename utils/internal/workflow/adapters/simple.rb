module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow
      def execute()
        results = Hash.new
        if @type == :sequential
          @elements.each{|action| results << execute_on_node(action)}
        elsif @type == :concurrent
          threads = @elements.map do |action| 
            Thread.new do 
              result = execute_on_node(action)
              @lock.synchronize{results[action[:id]] = result}
            end
          end
          threads.each{|t| t.join}
        end
        pp [:results, results]
      end
     private 
      def execute_on_node(action)
        begin
          cac = CommandAndControl.create()
          data = cac.dispatch_to_client(action)
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
