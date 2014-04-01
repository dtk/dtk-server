# TODO: right now these are for mcollecetive actions; hard coding get_netstat based on get_logs, wil then making general so can add custom actions
module DTK
  class Assembly::Instance
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

      def initiate_ssh_agent_action(agent_action, queue, params)
        nodes = get_nodes(:id,:display_name,:external_ref)
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
        Action::ExecuteTests.initiate(nodes,action_results_queue, :assembly, components)
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
        class ExecuteTests < ActionResultsQueue::Result
          def self.initiate(nodes,action_results_queue, type, components)

            #TODO: Rich: Put in logic here to get component instnces so can call an existing function used for converge to get all
            cmp_templates = get_component_templates(nodes,components)
            pp [:debug_cmp_templates,cmp_templates]
            version_context = 
              unless cmp_templates.empty?
                ComponentModule::VersionContextInfo.get_in_hash_form_from_templates(cmp_templates)
              else
                Log.error("Unexpected that cmp_instances is empty")
                nil
              end
            pp [:debug_version_context,version_context]

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

            #part of the code used to decide which components belong to which nodes. 
            #based on that fact, serverspec tests will be triggered on node only for components that actually belong to that specific node
            node_hash = {}
            components_including_node_name = []
            unless components.empty?
              nodes.each do |node|
                puts "Components: #{components}"
                components_array = []
                components.each do |comp|
                  if comp.include? "#{node[:display_name]}/"
                    components_array << comp
                    components_including_node_name << comp
                  end
                end
                node_hash[node[:id]] = {:components => components_array, :instance_id => node[:external_ref][:instance_id], :version_context => version_context}
              end
            end

            #components_including_node_name array will be empty if execute-test agent is triggered from specific node context
            if components_including_node_name.empty?
              CommandAndControl.request__execute_action(:execute_tests,:execute_tests,nodes,callbacks, {:components => components, :version_context => version_context})
            else
              CommandAndControl.request__execute_action_per_node(:execute_tests,:execute_tests,node_hash,callbacks)
            end
          end
         private
          #TODO: some of this logic can be leveraged by code below node_hash
          #TODO: even more idea, but we can iterate to it have teh controller/helper methods convert to ids and objects, ratehr than passing 
          #strings in components
          def self.get_component_templates(nodes,components)
            ret = Array.new
            if nodes.empty?
              return ret
            end
            sp_hash = {
              :cols => [:id,:group_id,:instance_component_template_parent,:node_node_id],
              :filter => [:oneof,:node_node_id,nodes.map{|n|n.id()}]
            }
            ret = Model.get_objs(nodes.first.model_handle(:component),sp_hash).map do |r|
              r[:component_template].merge(:node_node_id => r[:node_node_id])
            end
            if components.nil? or components.empty? or !components.include? "/"
              return ret
            end
          
            cmp_node_names = components.map do |name_pairs|
              if name_pairs.include? "/"
                split = name_pairs.split('/') 
                if split.size == 2
                  {:node_name => split[0],:component_name => Component.display_name_from_user_friendly_name(split[1])}
                else
                  Log.error("unexpected component form: #{name_pairs}; skipping")
                  nil
                end
              else
                {:component_name => Component.display_name_from_user_friendly_name(name_pairs)}
              end
            end.compact
            ndx_node_names = nodes.inject(Hash.new){|h,n|h.merge(n[:id] => n[:display_name])}
            
            #only keep matching ones
            ret.select do |cmp_template|
              cmp_node_names.find do |r|
                r[:node_name] == ndx_node_names[cmp_template[:node_node_id]] and r[:component_name] == cmp_template[:display_name]
              end
            end
          end
        end
      end
    end
  end
end
