module DTK
  module CommandAndControlAdapter
    class Server < CommandAndControlNodeConfig
      def self.execute(_task_idh, _top_task_idh, task_action)
        response = nil
        config_agent_type = task_action.config_agent_type
        if type = ConfigAgent::Type.is_a?(config_agent_type, [:ruby_function, :no_op])
          response = ConfigAgent.load(:ruby_function).execute(task_action)
        else
          Log.error("Not treating server execution of config_agent_type '#{config_agent_type}'")
        end

        # unless response is returned from ruby function send status: OK
        response ||= {
          statuscode: 0,
          statusmsg: 'OK"',
          data: { status: :succeeded }
        }
        response
      end
    end
  end
end
