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
##TODO: for some reason this debug statement does not spit ot instance mebers of error
##pp [:results, results]
puts "------------results-------------"
(results||{}).each do |key,result|
  if result[:error] and result[:error].respond_to?(:debug_pp_form)
    puts Aux::pp_form({key => result.merge(:error => result[:error].debug_pp_form)})
  else
    #TODO: very weir getting parsing error for pp {key => result}
    x = Hash.new; x[key]=result; pp x
  end
end
puts "------------end results-------------"
#### end of debug
      end
     private 
      def initialize(ordered_actions)
        @type = ordered_actions.is_concurrent?() ? :concurrent : :sequential
        @elements = ordered_actions.is_single_state_change?() ? [ordered_actions.single_state_change()] : ordered_actions.elements
        @lock = Mutex.new
        #TODO: put in max threads
     end
    end
  end
end
