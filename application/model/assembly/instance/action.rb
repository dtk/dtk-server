#TODO: right now these are for mcollecetive actions; hard coding get_netstat based on get_logs, wil then making general so can add custom actions
module DTK
  class AssemblyInstance
    module ActionMixin
      def execute_get_netstats()
        nodes = get_nodes(:id,:external_ref)
        callbacks = {
          :on_msg_received => proc do |msg|
            response = CommandAndControl.parse_response__execute_action(nodes,msg)
            if response[:status] == :ok
              #TODO: write
            else
              Log.error("error response for request to get_netstats")
              #TODO: put some subset of this in error msg
              pp msg
            end
          end
        }
        #TODO: want rpc mechanism that blocks for results
        CommandAndControl.request__execute_action(:netstat,:nltpu,nodes,callbacks)
      end
    end
  end
end
