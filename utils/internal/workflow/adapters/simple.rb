module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow
      def execute()
        results = Array.new
        if @type == :sequential
          @elements.each{|action| results << execute_on_node(action)}
        elsif @type == :concurrent
          #TODO: do we need mutex for setting value on results
          threads = @elements.map{|action| Thread.new{results << execute_on_node(action)}}
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
        #TODO: put in max threads
     end
    end
  end
end
