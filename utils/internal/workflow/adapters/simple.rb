module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow
      def execute()
        results = Hash.new
        #TODO: assuming that elements are node_actions
        if @type == :sequential
          @elements.each do |node_actions|
            results[node_actions[:id]] = create_or_execute_on_node(node_actions)
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
        pp [:results, results]
      end
     private 
      def initialize(ordered_actions)
        @type = ordered_actions.is_concurrent?() ? :concurrent : :sequential
        @elements = ordered_actions.is_single_action?() ? [ordered_actions.single_action()] : ordered_actions.elements
        @lock = Mutex.new
        #TODO: put in max threads
     end
    end
  end
end
