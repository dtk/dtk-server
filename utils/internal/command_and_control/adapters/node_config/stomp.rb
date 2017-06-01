#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
r8_nested_require('stomp', 'multiplexer')
r8_nested_require('messaging', 'assembly_action')
r8_nested_require('messaging', 'config')
r8_nested_require('stomp', 'stomp_listener')

module DTK
  module CommandAndControlAdapter
    class Stomp < CommandAndControl::NodeConfig
      extend Messaging::AssemblyActionClassMixin

      DEFAULT_TIMEOUT_AUTH_NODE = 60
      DEFAULT_TIMEOUT_CHECKALIVE = 5
      DOCKER_EXECUTOR_PBUILDERID = 'docker-executor'

      Lock = Mutex.new

      def self.server_host
        R8::Config[:stomp][:host]
      end

      def self.server_port
        (R8::Config[:stomp][:port]||'').to_i
      end

      def self.install_script(node, bindings)
        Messaging::Config.install_script(node, bindings)
      end

      def self.cloud_config_options(node, bindings)
        Messaging::Config.cloud_config_options(node, bindings)
      end

      def self.cloud_config_os_type
        Messaging::Config.cloud_config_os_type
      end

      def self.get_stomp_client(force_init=false)
        Lock.synchronize do
          @@stomp_client = nil if force_init
          @@stomp_client ||= create_stomp_client()
        end
      end

      def self.create_stomp_client
        Log.info("Trying to connect to STOMP server at #{server_host}:#{server_port} ...")
        ret = R8EM.connect  server_host, server_port, DTK::StompListener
        ret
      end

      def self.poll_to_detect_node_ready(node, opts)
        rc = opts[:receiver_context]
        callbacks = {
          on_msg_received: proc do |msg|
            rc[:callbacks][:on_msg_received].call(msg) unless (node[:is_task_canceled] || node[:is_task_failed])
          end
        }

        pbuilderid = Node.pbuilderid(node)
        filter = filter_single_fact('pbuilderid', pbuilderid)

        async_agent_call('discovery', 'ping', {}, filter, callbacks, rc)
      end

      def self.authorize_node(node, callbacks, context_x = {})
        repo_user_mh = node.id_handle.createMH(:repo_user)

        node_repo_user = RepoUser.get_matching_repo_user(repo_user_mh, { type: :node }, [:ssh_rsa_private_key, :ssh_rsa_pub_key])

        unless node_repo_user && node_repo_user[:ssh_rsa_private_key]
          fail Error.new('Cannot found ssh private key to authorize nodes')
        end
        unless node_repo_user[:ssh_rsa_pub_key]
          fail Error.new('Cannot found ssh public key to authorize nodes')
        end

        pbuilderid = Node.pbuilderid(node)
        filter = filter_single_fact('pbuilderid', pbuilderid)

        params = {
          agent_ssh_key_public: node_repo_user[:ssh_rsa_pub_key],
          agent_ssh_key_private: node_repo_user[:ssh_rsa_private_key],
          server_ssh_rsa_fingerprint: RepoManager.repo_server_ssh_rsa_fingerprint()
        }
        # use a short timeout for certain agents when running on docker-executor
        # it's expected that dtk-arbiter container is always up and ready
        timeout = pbuilderid.eql?(DOCKER_EXECUTOR_PBUILDERID) ? DEFAULT_TIMEOUT_CHECKALIVE : DEFAULT_TIMEOUT_AUTH_NODE
        context = { timeout: timeout }.merge(context_x)

        async_agent_call('git_access', 'add_rsa_info', params, filter, callbacks, context)
      end

      def self.async_agent_call(agent, method, params, filter_x, callbacks, context_x)
        msg = {
          agent: agent,
          method: method
        }

        msg.merge!(params.delete(:action_agent_request)) if params[:action_agent_request]
        msg.merge!(params)

        filter = BlankFilter.merge(filter_x).merge('agent' => [agent])
        context = context_x.merge(callbacks: callbacks)

        handler.sendreq_with_callback(msg, agent, context, filter)
      end

      def self.check_alive(filter, callbacks, context, task_idh, &callback_on_success)
        # send a ping message, to make sure dtk-arbiter is up and listening
        # this request will have a much shorter timeout
        callbacks_checkalive = {
          on_msg_received: proc do |msg|
            Log.info("Check-alive succeeded.") 
            DTK::Task.checked_nodes.delete_if { |h| h[msg[:pbuilderid]] }
            callback_on_success.call
          end,
          on_timeout: proc do |msg|
            Log.error("Check-alive timeout detected.")
            begin
              DTK::Workflow.cancel(task_idh.create_object)
              task_idh.create_object.add_event_and_errors(:complete_timeout, :server, ["Detected that dtk-arbiter is down"])
            rescue Exception => e
              Log.error("Error in cancel ExecuteOnNode #{e.class}")
              fail e unless e.is_a?(ErrorUsage)
            end
            DTK::Task.checked_nodes.clear
          end
        }
        context_checkalive = context.merge(:timeout => DEFAULT_TIMEOUT_CHECKALIVE)
        pbuilderid = filter["fact"].find{ |f| f[:value] if f[:fact].eql?('pbuilderid') }[:value]
        checkalive_validity = Time.now + DEFAULT_TIMEOUT_CHECKALIVE
        DTK::Task.add_to_checked({pbuilderid => checkalive_validity})
        Log.debug "Check-alive added to checked nodes: #{DTK::Task.checked_nodes}"

        async_agent_call('discovery', 'ping', {}, filter, callbacks_checkalive, context_checkalive)
      end

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

        # TODO: DTK-2938: commented out check alive because added complexity does not seem to give that much value
        # Also now that detect node is done before any component on node run check alive may
        # not be providing any value; we can look at enhancing detect node is up by dynamically setting
        # number of reties and time between retries and calling detect node is up on assembly wide nodes too
        #
        # Do a check-alive of arbiter
        # unless discovery or git_access agents are called since they're executed on node initialization
        # or node already checked
        # callback_mode = false
        # if node_checked?(DTK::Task.checked_nodes, pbuilderid)
        #  DTK::Task.checked_nodes.delete_if { |h| h[pbuilderid] }
        # elsif !['git_access', 'discovery'].include?(mc_info[:agent])
        #  check_alive(filter, callbacks, context, task_idh) do
        #    async_agent_call(mc_info[:agent], mc_info[:action], msg_content, filter, callbacks, context)
        #  end
        #  callback_mode = true
        # end
        # async_agent_call(mc_info[:agent], mc_info[:action], msg_content, filter, callbacks, context) unless callback_mode

        async_agent_call(mc_info[:agent], mc_info[:action], msg_content, filter, callbacks, context) 
      end

      def self.node_checked?(checked_nodes, pbuilderid)
        checked_nodes_match = checked_nodes.select { |h| h[pbuilderid]}.first
        checked = checked_nodes_match && checked_nodes_match[pbuilderid] > Time.now
        Log.debug("Node #{pbuilderid} already checked: #{checked}")
        checked
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

      def self.initiate_cancelation(task_idh, top_task_idh, config_node, opts)
        msg_content = { 
          task_id: task_idh.get_id, 
          worker: worker_for_cancelation_msg(config_node),
          top_task_id: top_task_idh.get_id, 
        }
        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact('pbuilderid', pbuilderid)
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        async_agent_call('cancel_action', 'run', msg_content, filter, callbacks, context)
      end

      # TODO: hack for DTK-2886
      def self.worker_for_cancelation_msg(config_node)
        case config_agent_type = config_node[:config_agent_type]
        when 'dynamic' then 'generic'
        else config_agent_type
        end
      end
      private_class_method :worker_for_cancelation_msg

      def self.action_results(result, action)
        if config_agent = config_agent_object?(action)
          if config_agent.respond_to?(:action_results)
            config_agent.action_results(result, action)
          else
            Log.error_pp(['Config agent does not have action_results defined:', config_agent])
            nil
          end
        end
      end

      def self.errors_in_node_action_result?(result, action = nil)
        if result[:statuscode] != 0
          status_code_errors(result)
        else
          payload = result[:data] || {}
          errors_in_node_action_payload?(payload, action)
        end
      end

      private

      def self.status_code_errors(result)
        error_message = 
          if message = result[:statusmsg] || result[:error_type]
            "Action failed with status code #{result[:statuscode]}: #{message}"
          else
            # TODO: legacy that needs to be cleaned up
            action_results = (result[:data] || {})[:data] || []
            errors = action_results.select { |r| r[:status] != 0 }.uniq
            if errors.empty?
              nil
            else
              errors.map do |r|
                r[:error] ? r[:error] : "Action '#{r[:description]}' failed with status code #{r[:status]}, output: #{r[:stderr]}"
              end.join(', ')
            end
          end
        [{ message: error_message || "Unknown error" }]
      end

      def self.config_agent_object?(action)
        if action
          if action.respond_to?(:config_agent_object)
            action.config_agent_object
          else
             ConfigAgent.load(action.config_agent_type)
          end
        end                   
      end

      def self.errors_in_node_action_payload?(payload, action = nil)
        ret = nil
        answer_computed = false
        if config_agent = config_agent_object?(action)
          if config_agent.respond_to?(:errors_in_result?)
            answer_computed = true
            ret = config_agent.errors_in_result?(payload, action)
          end
        end
        answer_computed ? ret : errors_in_node_action_payload_default?(payload)
      end

      def self.errors_in_node_action_payload_default?(payload)
        unless [:succeeded, :ok].include?(payload[:status])
          payload[:error] ? [payload[:error]] : (payload[:errors] || [])
        end
      end

      BlankFilter = { 'identity' => [], 'fact' => [], 'agent' => [], 'cf_class' => [] }
      @@handler = nil

      def self.handler
        @@handler ||= StompMultiplexer.create(self.get_stomp_client())
      end
    end
  end
end

