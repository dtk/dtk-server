module DTK
  module DeveloperMixin
  	def self.initiate_inject_agent(action_results_queue, nodes, params)
        Action::InjectAgent.initiate(nodes,action_results_queue, params)
    end

    module Action
    	class InjectAgent < ActionResultsQueue::Result
        def self.initiate(nodes, action_results_queue, params)
          # if nodes empty return error message, case where more nodes are matches should not happen
          if nodes.empty?
            action_results_queue.push(:error, "No nodes have been matched to node identifier: #{params[:node_pattern]}") 
            return
          end

          indexes = nodes.map{|r|r[:id]}
          action_results_queue.set_indexes!(indexes)
          ndx_pbuilderid_to_node_info =  nodes.inject(Hash.new) do |h,n|
            h.merge(n.pbuilderid => {:id => n[:id], :display_name => n[:display_name]}) 
          end

          callbacks = {
            :on_msg_received => proc do |msg|
              response = CommandAndControl.parse_response__execute_action(nodes,msg)

              if response and response[:pbuilderid] and response[:status] == :ok
                node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
                action_results_queue.push(node_info[:id],response[:data])
              end
            end
          }

          CommandAndControl.request__execute_action(:dev_manager,:inject_agent,nodes,callbacks,params)
        end
      end
    end
  end
end