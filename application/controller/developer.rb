module XYZ
  class DeveloperController < AuthController
    helper :node_helper
    helper :assembly_helper

    def rest__update_action_agent()
      service_name, branch_name = ret_request_params(:service_name, :branch_name)
      service = ret_assembly_instance_object(:service_name)

      # DEBUG SNIPPET >>> REMOVE <<<
      require (RUBY_VERSION.match(/1\.8\..*/) ? 'ruby-debug' : 'debugger');Debugger.start; debugger

      queue_id =initiate_agent(:dev_manager, :inject_agent, service.nodes, { action_agent_branch: branch_name, action_agent_remote_url: R8::Config[:action_agent_sync][:remote_url]})
      rest_ok_response :action_results_id => queue_id
    end


  private


    def initiate_agent(agent_name, agent_method, nodes, params)
      action_results_queue = ActionResultsQueue.new

      # if nodes empty return error message, case where more nodes are matches should not happen
      if nodes.empty?
        action_results_queue.push(:error, "No nodes provided for given action, aborting operation mcollective agent (#{agent_name.capitalize}##{agent_method})")
        return
      end

      indexes = nodes.map { |r| r[:id] }
      action_results_queue.set_indexes!(indexes)
      ndx_pbuilderid_to_node_info =  nodes.inject(Hash.new) do |h, node|
        h.merge(node.pbuilderid => { :id => node.id, :display_name => node.name } )
      end

      callbacks = {
        :on_msg_received => proc do |msg|
          response = CommandAndControl.parse_response__execute_action(nodes, msg)

          if response and response[:pbuilderid] and response[:status] == :ok
            node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
            action_results_queue.push(node_info[:id],response[:data])
          end
        end
      }

      CommandAndControl.request__execute_action(agent_name, agent_method, nodes, callbacks, params)

      action_results_queue.id
    end

  end
end