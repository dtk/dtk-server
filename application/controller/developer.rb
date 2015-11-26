require 'json'

module XYZ
  class DeveloperController < AuthController
    helper :node_helper
    helper :assembly_helper

    def rest__run_agent()
      agent_name, agent_method, agent_params = ret_request_params(:agent_name, :agent_method, :agent_params)
      service = ret_assembly_instance_object(:service_name)

      agent_hash = JSON.parse(agent_params)
      agent_hash = agent_hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      agent_hash.merge!(:protocol => 'stomp')

      Log.info("Running Agent #{agent_name}, method: #{agent_method} with params: ")
      Log.info(agent_hash)

      queue_id = initiate_agent(agent_name.downcase.to_sym, agent_method.downcase.to_sym, service.nodes, agent_hash)
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
          response = CommandAndControl.parse_response__execute_action(nodes, msg, params)

          if response and response[:pbuilderid]
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