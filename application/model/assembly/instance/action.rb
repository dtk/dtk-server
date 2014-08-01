module DTK
  class Assembly::Instance
    module Action
      r8_nested_require('action','execute_tests')
      class GetLog < ActionResultsQueue
       private
        def action_hash()
          {:agent => :tail, :method => :get_log}
        end
      end
      class Grep < ActionResultsQueue
       private
        def action_hash()
          {:agent => :tail, :method => :grep}
        end
      end

      class GetPs < ActionResultsQueue
       private
        def action_hash()
          {:agent => :ps, :method => :get_ps}
        end

        def process_data!(data,node_info)
          Result.new(node_info[:display_name],data.map{|r|node_info.merge(r)})
        end
      end

      class GetNetstats < ActionResultsQueue
       private
        def action_hash()
          {:agent => :netstat, :method => :get_tcp_udp}
        end

        def process_data!(data,node_info)
          ndx_ret = Hash.new
          data.each do |r|
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
          Result.new(node_info[:display_name],ndx_ret.values)
        end
      end
    end

#TODO: cleanup everything below this
    module ActionMixin
      def initiate_execute_tests(action_results_queue, node_id=nil, components=nil)
        nodes =  action_get_leaf_nodes()
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
        
        nodes =  action_get_leaf_nodes()
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

      def action_get_leaf_nodes()
        get_leaf_nodes(:cols => [:id,:display_name,:external_ref])
      end

      module Action
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
      end
    end
  end
end
