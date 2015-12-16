require 'json'
require 'active_support/core_ext/hash/keys'

module XYZ
  class DeveloperController < AuthController
    helper :node_helper
    helper :assembly_helper

    def rest__run_agent()
      agent_name, agent_method, agent_params = ret_request_params(:agent_name, :agent_method, :agent_params)
      service = ret_assembly_instance_object(:service_name)

      params = {}

      agent_hash = JSON.parse(agent_params)
      agent_hash = deep_convert(agent_hash)

      agent_hash.merge!(
{:components_with_attributes=>
  [{"component_type"=>"class",
    "name"=>"stdlib",
    "id"=>2147549352,
    "module_name"=>"stdlib"}],
 :node_manifest=>
  [["$extlookup_datadir = '/etc/puppet/manifests/extdata'",
    "$extlookup_precedence = ['common']",
    "$dtk_assembly_node = \"test1\"",
    "$dtk_assembly_node_type = \"node\"",
    "$dtk_assembly_node_base_name = \"test1\"",
    "$dtk_assembly_node_index = \"\"",
    "stage{1:}",
    " ",
    "class {\"stdlib\": stage => 1}"]],
 :inter_node_stage=>"1",
 :version_context=>
  [{:id=>2147526308,
    :repo=>"dtk16-r8-stdlib",
    :branch=>"workspace-private-dtk16",
    :implementation=>"stdlib",
    :sha=>"d2b2e8a1242c79827c9352f9867598b0090913c5"}],
 :puppet_version=>nil,
 :service_id=>2147549347,
 :service_name=>"haris-demo",
 :task_id=>2147549363,
 :top_task_id=>2147549360,
 :agent_git_details=>{:repo=>"dtk-node-agent", :branch=>""}})


      params.merge!(:protocol => 'stomp')
      params.merge!(:action_agent_request => agent_hash)

      Log.info("Running Agent #{agent_name}, method: #{agent_method} with params: ")
      Log.info(params)

      queue_id = initiate_agent(agent_name.downcase.to_sym, agent_method.downcase.to_sym, service.nodes, params)
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

    def deep_convert(element)
      return element.collect { |e| deep_convert(e) } if element.is_a?(Array)
      return element.inject({}) { |sh,(k,v)| sh[k.to_sym] = deep_convert(v); sh } if element.is_a?(Hash)
      element
    end

  end
end