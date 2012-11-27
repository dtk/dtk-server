#TODO: right now these are for mcollecetive actions; hard coding get_netstat based on get_logs, wil then making general so can add custom actions
module DTK
  class Assembly::Instance
    module ActionMixin
      def initiate_get_netstats(action_results_queue)
        nodes = get_nodes(:id,:display_name,:external_ref)
        Action::GetNetstats.initiate(nodes,action_results_queue)
      end

      def initiate_get_log(action_results_queue,params)
        # start of get log functionality
        nodes = get_nodes(:id,:display_name,:external_ref)
        Action::GetLog.initiate(nodes,action_results_queue,params)
      end

      module Action
        class GetLog < ActionResultsQueue::Result
          def self.initiate(nodes, action_results_queue, params)
            # filters nodes based on requested node identifier
            nodes = nodes.select { |node| node[:id] == params[:node_identifier].to_i || node[:display_name] == params[:node_identifier] }
            
            # if nodes empty return error message, case where more nodes are matches should not happen
            if nodes.empty?
              action_results_queue.push(:error, "No nodes have been mathed to node identifier: #{params[:node_identifier]}") 
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

            CommandAndControl.request__execute_action(:tail,:get_log,nodes,callbacks,params)
          end
        end
        class GetNetstats < ActionResultsQueue::Result
          def self.initiate(nodes,action_results_queue)
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
                  raw_data = response[:data].map{|r|node_info.merge(r)}
                  data = process_data_for_ipv4(raw_data)
                  action_results_queue.push(node_info[:id],new(node_info[:display_name],data))

                end
              end
            }
            CommandAndControl.request__execute_action(:netstat,:get_tcp_udp,nodes,callbacks)
          end
          private
          def self.process_data_for_ipv4(raw_data)
            ndx_ret = Hash.new
            raw_data.each do |r|
              next unless r[:state] == "LISTEN"
              if r[:local] =~ /(^.+):([0-9]+$)/
                address = $1
                address = "0.0.0.0" if address == "::"
                port = $2.to_i
                next unless address =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/
                ndx_ret[port] ||= {
                  :port => port,
                  :local_address => address,
                  :protocol => r[:protocol]
                }
              end
            end
            ndx_ret.values
          end
        end
      end
    end
  end
end
