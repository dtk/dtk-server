r8_nested_require('stomp', 'multiplexer')
r8_nested_require('mcollective', 'assembly_action')
require 'stomp'

module DTK
  module CommandAndControlAdapter
    class Stomp < CommandAndControlNodeConfig
      extend Mcollective::AssemblyActionClassMixin

      Lock = Mutex.new

      def self.server_host
        R8::Config[:command_and_control][:node_config][:mcollective][:host]
      end

      def self.server_port
        R8::Config[:mcollective][:port]
      end

      def self.get_stomp_client
        Lock.synchronize do
          @@stomp_client ||= create_stomp_client()
        end
      end

      def self.create_stomp_client
        configuration = {
          stomp_username: R8::Config[:mcollective][:username],
          stomp_password: R8::Config[:mcollective][:password],
          stomp_host: 'localhost',
          stomp_port: R8::Config[:mcollective][:port].to_i
        }
        ret = ::Stomp::Client.new(:hosts => [{:login => configuration[:stomp_username], :passcode => configuration[:stomp_password], :host => configuration[:stomp_host], :port => configuration[:stomp_port], :ssl => false}])
        ret
      end

      def self.parse_response__execute_action(_nodes, msg)
        # we transform msg to be in format of mcollective
        mcollective_msg = {
          body: { data: msg, statuscode: msg[:statuscode] }
        }
        super(_nodes, mcollective_msg)
      end

      # TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_execution(task_idh, top_task_idh, config_node, opts)
        config_agent = ConfigAgent.load(config_node[:config_agent_type])

        opts_ret_msg = {}
        if assembly = assembly_instance(task_idh, config_node)
          opts_ret_msg.merge!(assembly: assembly)
        end

        task_id     = task_idh.get_id()
        top_task_id = top_task_idh.get_id()
        msg_content = config_agent.ret_msg_content(config_node, opts_ret_msg.merge!(task_id: task_id, top_task_id: top_task_id))

        added_content = {
          task_id: task_id,
          top_task_id: top_task_id,
          agent_git_details: { repo: 'dtk-node-agent', branch: '' }
        }
        msg_content.merge!(added_content)

        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact('pbuilderid', pbuilderid)
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        mc_info = mc_info_for_config_agent(config_agent)
        async_agent_call(mc_info[:agent], mc_info[:action], msg_content, filter, callbacks, context)
      end

      # TODO: below is hack and should find more reliable way to pass in assembly
      def self.assembly_instance(task_idh, config_node)
        assembly_id =
          if assembly_idh = config_node[:assembly_idh]
            if assembly_idh.is_a?(IDHandle) then assembly_idh.get_id()
            elsif assembly_idh.is_a?(Hash) then assembly_idh[:guid]
            end
          else
            # TODO: think this is reached for node group member; need to check if reached under any other condition
            if component_actions = config_node[:component_actions]
              if component = component_actions.first && component_actions.first[:component]
                component.get_field?(:assembly_id)
              end
            end
          end

        if assembly_id
          task_idh.createIDH(model_name: :assembly_instance, id: assembly_id).create_object()
        else
          Log.error("Could not find assembly id for task with id '#{task_idh.get_id()}'")
          nil
        end
      end
      private_class_method :assembly_instance

      # TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_cancelation(task_idh, top_task_idh, config_node, opts)
        # DEBUG SNIPPET >>> REMOVE <<<
        require (RUBY_VERSION.match(/1\.8\..*/) ? 'ruby-debug' : 'debugger');Debugger.start; debugger
        msg_content = { task_id: task_idh.get_id(), top_task_id: top_task_idh.get_id() }
        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact('pbuilderid', pbuilderid)
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        async_agent_call('puppet_cancel', 'run', msg_content, filter, callbacks, context)
      end

      def self.action_results(result, action)
        if config_agent = config_agent_for_action?(action)
          if config_agent.respond_to?(:action_results)
            config_agent.action_results(result, action)
          else
            Log.error_pp(['Config agent does not have action_results defined:', config_agent])
            nil
          end
        end
      end

      def self.errors_in_node_action_result?(result, action = nil)
        # DEBUG SNIPPET >>> REMOVE <<<
        require (RUBY_VERSION.match(/1\.8\..*/) ? 'ruby-debug' : 'debugger');Debugger.start; debugger
        # result[:statuscode] is for mcollective agent errors and data is for errors for agent
        error_type = result[:error_type] || 'node agent error'
        if result[:statuscode] != 0
          statusmsg = result[:statusmsg]
          err_msg = (statusmsg ? "#{error_type}: #{statusmsg}" : "#{error_type}")
          [{ message: err_msg }]
        else
          payload = result[:data] || {}
          errors_in_node_action_payload?(payload, action)
        end
      end

      private

      def self.config_agent_for_action?(action)
        # DEBUG SNIPPET >>> REMOVE <<<
        require (RUBY_VERSION.match(/1\.8\..*/) ? 'ruby-debug' : 'debugger');Debugger.start; debugger
        if config_agent_type = action && action.config_agent_type
          ConfigAgent.load(config_agent_type)
        end
      end

      def self.errors_in_node_action_payload?(payload, action = nil)
        # DEBUG SNIPPET >>> REMOVE <<<
        require (RUBY_VERSION.match(/1\.8\..*/) ? 'ruby-debug' : 'debugger');Debugger.start; debugger
        ret = nil
        answer_computed = false
        if config_agent = config_agent_for_action?(action)
          if config_agent.respond_to?(:errors_in_result?)
            answer_computed = true
            ret = config_agent.errors_in_result?(payload, action)
          end
        end
        answer_computed ? ret : errors_in_node_action_payload_default?(payload)
      end

      def self.async_agent_call(agent, method, params, filter_x, callbacks, context_x)
        msg = {
          agent: agent,
          method: method
        }
        msg.merge!(params[:action_agent_request]) if params[:action_agent_request]

        filter = BlankFilter.merge(filter_x).merge('agent' => [agent])
        context = context_x.merge(callbacks: callbacks)
        handler.sendreq_with_callback(msg, agent, context, filter)
      end

      BlankFilter = { 'identity' => [], 'fact' => [], 'agent' => [], 'cf_class' => [] }
      @@handler = nil

      def self.handler
        @@handler ||= StompMultiplexer.create(self.get_stomp_client())
      end
    end
  end
end
