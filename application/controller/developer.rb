r8_require("../model/developer")
module XYZ
  class DeveloperController < AuthController
    include DeveloperMixin
  	helper :node_helper

  	def rest__inject_agent()
  		params = ret_params_hash(:agent_files, :node_pattern)
  		node = create_node_obj(:node_pattern)
      queue = ActionResultsQueue.new

      DeveloperMixin.initiate_inject_agent(queue, [node], params)
      rest_ok_response :action_results_id => queue.id
    end
  end
end