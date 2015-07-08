module DTK
  module CommandAndControlAdapter
    class Server < CommandAndControlNodeConfig
      def self.execute(_task_idh,_top_task_idh,task_action)
        response = nil
        config_agent_type = task_action.config_agent_type
        # DTK-2037: Aldin; clean up when we determine whether we use 'ruby_function' as the provider type instaed of dtk_provider
        if ['dtk_provider'].include?(config_agent_type)
          if task_action.ruby_function_implementation?
            response = ConfigAgent.load(:ruby_function).execute(task_action)
          else
            Log.error("Unexepected that task_action.ruby_function_implementation? is false")
          end
        else
          Log.error("Not treating server execution of config_agent_type '#{config_agent_type}'")
        end

        # unless response is returned from ruby function send status: OK
        response ||= {
          statuscode: 0, 
          statusmsg: 'OK"', 
          data: {status: :succeeded}
        }
        response
      end
    end
  end
end        

