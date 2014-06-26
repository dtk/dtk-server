# TODO: right now these are for mcollecetive actions; hard coding get_netstat based on get_logs, wil then making general so can add custom actions
module DTK
  class Assembly::Instance
    module Action
      r8_nested_require('action','execute_tests')
    end

    module ActionMixin
      def initiate_get_netstats(action_results_queue, node_id=nil)
        nodes = get_nodes(:id,:display_name,:external_ref)
        nodes = nodes.select { |node| node[:id] == node_id.to_i } unless (node_id.nil? || node_id.empty?)
        Action::GetNetstats.initiate(nodes,action_results_queue)
      end

      def initiate_get_log(action_results_queue,params)
        # start of get log functionality
        nodes = get_nodes(:id,:display_name,:external_ref)
        Action::GetLog.initiate(nodes,action_results_queue,params)
      end

      def initiate_grep(action_results_queue,params)
        # start of get log functionality
        nodes = get_nodes(:id,:display_name,:external_ref)
        Action::Grep.initiate(nodes,action_results_queue,params)
      end

      def initiate_ssh_agent_action(agent_action, queue, params, nodes)
        Action::SSHAccess.initiate(nodes, queue, params, agent_action)
      end

      def initiate_get_ps(action_results_queue, node_id=nil)
        nodes = get_nodes(:id,:display_name,:external_ref)
        nodes = nodes.select { |node| node[:id] == node_id.to_i } unless (node_id.nil? || node_id.empty?)
        Action::GetPs.initiate(nodes,action_results_queue, :assembly)
      end

      def initiate_execute_tests(action_results_queue, node_id=nil, components=nil)
        nodes = get_nodes(:id,:display_name,:external_ref)
        nodes = nodes.select { |node| node[:id] == node_id.to_i } unless (node_id.nil? || node_id.empty?)
        
        # Special case filtering of nodes that are not running and executing agent only on those that are running
        component_nodes = Array.new
        
        unless components.empty? || components.nil?
          components.each do |cmp|
            if cmp.include? "/"
              component_nodes << cmp.split("/").first
            end
          end
        end
        nodes = nodes.select { |node| component_nodes.include? node[:display_name] } if (node_id.nil? || node_id.empty?)
        Assembly::Instance::Action::ExecuteTests.initiate(nodes,action_results_queue, :assembly, components)
      end

      def initiate_execute_tests_v2(project,action_results_queue, node_id=nil, components=nil)
        
        nodes = get_nodes(:id,:display_name,:external_ref)
        nodes = nodes.select { |node| node[:id] == node_id.to_i } unless (node_id.nil? || node_id.empty?)
        opts = {} 

        # Special case filtering of nodes that are not running and executing agent only on those that are running
        component_nodes = Array.new
        unless components.empty? || components.nil?
          components.each do |cmp|
            if cmp.include? "/"
              component_nodes << cmp.split("/").first
            end
          end
          opts.merge!(:filter => {:components => components})
        end
        Assembly::Instance::Action::ExecuteTestsV2.initiate(project,self,nodes,action_results_queue, :assembly, opts)
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

        class SSHAccess < ActionResultsQueue::Result

          def self.initiate(nodes, action_results_queue, params, agent_action)
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

                  unless response[:data][:error]
                    component_type = :authorized_ssh_public_key
                    attr_hash = {
                      :linux_user => params[:system_user],
                      :key_name => params[:rsa_pub_name],
                      :key_content => params[:rsa_pub_key]
                    }
                    node = nodes.find { |n| n[:id] == node_info[:id] }

                    if (agent_action == :grant_access)
                      DTK::Component::Instance::Interpreted.create_or_update?(node,component_type,attr_hash)
                    else
                      DTK::Component::Instance::Interpreted.delete(node, component_type, attr_hash)
                    end
                  end

                  action_results_queue.push(node_info[:display_name],response[:data])
                else
                  Log.error("Agent '#{msg[:senderagent]}' error, Code: #{msg[:body][:statuscode]} - #{msg[:body][:statusmsg]}")
                end

              end
            }

            CommandAndControl.request__execute_action(:ssh_agent,agent_action,nodes,callbacks,params)
          end
        end

        class Grep < ActionResultsQueue::Result
          def self.initiate(nodes, action_results_queue, params)
            # filters nodes based on requested node identifier
            nodes = nodes.select { |node| (node[:id].to_s.start_with?(params[:node_pattern].to_s)) || (node[:display_name].to_s.start_with?(params[:node_pattern].to_s)) }
            
            # if nodes empty return error message, case where more nodes are matches should not happen
            if nodes.empty?
              action_results_queue.push(:error, "No nodes have been mathed to node identifier: #{params[:node_pattern]}") 
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

                response = ActionResultsQueue::Result.normalize_to_utf8_output(response)

                if response and response[:pbuilderid] and response[:status] == :ok
                  node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
                  action_results_queue.push(node_info[:id],response[:data])
                end
              end
            }
            CommandAndControl.request__execute_action(:tail,:grep,nodes,callbacks,params)
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
                # TODO: now ignoring bad results because have time out mechanism; might put errors in queue to terminate earlier
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
              next unless r[:state] == "LISTEN" || r[:protocol] == "udp"
              if r[:local] =~ /(^.+):([0-9]+$)/
                address = $1
                port = $2.to_i
                next unless address =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$|::/
                ndx_ret["#{address}_#{port}"] ||= {
                  :port => port,
                  :local_address => address,
                  :protocol => r[:protocol]
                }
              end
            end
            ndx_ret.values
          end
        end
        class GetPs < ActionResultsQueue::Result
          def self.initiate(nodes,action_results_queue, type)
            indexes = nodes.map{|r|r[:id]}
            action_results_queue.set_indexes!(indexes)
            ndx_pbuilderid_to_node_info =  nodes.inject(Hash.new) do |h,n|
              h.merge(n.pbuilderid => {:id => n[:id].to_s, :display_name => n[:display_name]}) 
            end
            callbacks = {
              :on_msg_received => proc do |msg|
                response = CommandAndControl.parse_response__execute_action(nodes,msg)
                if response and response[:pbuilderid] and response[:status] == :ok
                  node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
                  raw_data = response[:data].map{|r|node_info.merge(r)}
                  packaged_data = new(node_info[:display_name],raw_data)
                  action_results_queue.push(node_info[:id], (type == :node) ? packaged_data.data : packaged_data)
                end
              end
            }
            CommandAndControl.request__execute_action(:ps,:get_ps,nodes,callbacks)
          end
        end
      end
    end
  end
end
