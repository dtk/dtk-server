module DTK
  class Assembly::Instance
    module Action
      class GetLog < ActionResultsQueue::Result
        ##
        # Initiates commmand on nodes to tail logs
        #
        # The parameter +params+ can have keys: :log_path, :start_line
        def self.initiate(nodes, action_results_queue, params)
          indexes = nodes.map{|r|r[:id]}
          action_results_queue.set_indexes!(indexes)
          ndx_pbuilderid_to_node_info =  nodes.inject(Hash.new) do |h,n|
            h.merge(n.pbuilderid => {:id => n[:id], :display_name => n[:display_name]}) 
          end
          
          callbacks = {
            :on_msg_received => proc do |msg|
              response = CommandAndControl.parse_response__execute_action(nodes,msg)
              
              response = ActionResultsQueue::Result.normalize_to_utf8_output(response)
              
              if response and response[:pbuilderid] and response[:status] == :ok
                node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
                action_results_queue.push(node_info[:id],response[:data])
              end
            end
          }
          
          CommandAndControl.request__execute_action(:tail,:get_log,nodes,callbacks,params)
        end
      end
    end
  end
end
