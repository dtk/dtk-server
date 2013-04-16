r8_require("../model/developer")
module XYZ
  class DeveloperController < AuthController
    include DeveloperMixin
  	helper :node_helper

  	def rest__inject_agent()
  		params = ret_params_hash(:agent_files, :node_pattern, :node_list)
      node_list = params[:node_list]||[]
      nodes     = get_nodes_from_params(node_list)
      queue     = ActionResultsQueue.new

      DeveloperMixin.initiate_inject_agent(queue, nodes, params)
      rest_ok_response :action_results_id => queue.id
    end

    def get_nodes_from_params(node_list)
      nodes = []
      node_list.each do |n|
        nodes << get_objects(:node, { :id => n.to_i}).flatten
      end
      return nodes.flatten
    end

  end
end