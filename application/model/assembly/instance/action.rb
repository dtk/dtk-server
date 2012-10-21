#TODO: right now these are for mcollecetive actions; hard coding get_netstat based on get_logs, wil then making general so can add custom actions
module DTK
  class AssemblyInstance
    module ActionMixin
      def initiate_get_netstats(action_results_queue)
        nodes = get_nodes(:id,:display_name,:external_ref)
        indexes = nodes.map{|r|r[:id]}
        action_results_queue.set_indexes!(indexes)
        ndx_pbuilderid_to_node_info =  nodes.inject(Hash.new) do |h,n|
          h.merge(n.pbuilderid => {:id => n[:id], :display_name => n[:display_name]}) 
        end
        callbacks = {
          :on_msg_received => proc do |msg|
            response = CommandAndControl.parse_response__execute_action(nodes,msg)
            #TODO: now ignoring bad results because have time out mechanism; might put errors in queue to terminate earlier
            if response and response[:pbuilderid] and response[:status] == :ok
              node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
              data = response[:data].map{|r|node_info.merge(r)}
              action_results_queue.push(node_info[:id],data)
            end
          end
        }
        CommandAndControl.request__execute_action(:netstat,:get_tcp_udp,nodes,callbacks)
      end
    end
  end
end
