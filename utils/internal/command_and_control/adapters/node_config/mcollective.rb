require 'mcollective'
r8_nested_require('mcollective','monkey_patches')
module DTK
  module CommandAndControlAdapter
    class Mcollective < CommandAndControlNodeConfig
      r8_nested_require('mcollective','assembly_action')
      r8_nested_require('mcollective','multiplexer')
      r8_nested_require('mcollective','config')
      extend AssemblyActionClassMixin
      def self.server_host
        R8::Config[:command_and_control][:node_config][:mcollective][:host]
      end

      def self.discover(filter, timeout, limit, client)
        Config.discover(filter, timeout, limit, client)
      end

      def self.install_script(node,bindings)
        Config.install_script(node,bindings)
      end

      def self.get_mcollective_client
        Config.mcollective_client()
      end

      # TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_execution(task_idh,top_task_idh,config_node,opts)
        config_agent = ConfigAgent.load(config_node[:config_agent_type])

        opts_ret_msg = {}
        if assembly = assembly_instance(task_idh,config_node)
          opts_ret_msg.merge!(assembly: assembly)
        end

        msg_content = config_agent.ret_msg_content(config_node,opts_ret_msg)
        added_content = {
          task_id: task_idh.get_id(),
          top_task_id: top_task_idh.get_id(),
          agent_git_details: {repo: "dtk-node-agent", branch: "" }
        }
        msg_content.merge!(added_content)

        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact("pbuilderid",pbuilderid)
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        mc_info = mc_info_for_config_agent(config_agent)
        async_agent_call(mc_info[:agent],mc_info[:action],msg_content,filter,callbacks,context)
      end

      # TODO: below is hack and should find more reliable way to pass in assembly
      def self.assembly_instance(task_idh,config_node)
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
          task_idh.createIDH(model_name: :assembly_instance,id: assembly_id).create_object()
        else
          Log.error("Could not find assembly id for task with id '#{task_idh.get_id()}'")
          nil
        end
      end
      private_class_method :assembly_instance

      # TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_cancelation(task_idh,top_task_idh,config_node,opts)
        msg_content = { task_id: task_idh.get_id(),top_task_id: top_task_idh.get_id() }
        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact("pbuilderid",pbuilderid)
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        async_agent_call("puppet_cancel","run",msg_content,filter,callbacks,context)
      end

      # TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_sync_agent_code(_task_idh,_top_task_idh,config_node,opts)
        context = opts[:receiver_context]

        agent_repo_dir = R8::Config[:node_agent_git_clone][:local_dir]
        node_commit_id = config_node[:node][:agent_git_commit_id]
        unless head_git_commit_id = context[:head_git_commit_id]
          raise Error.new("Unexpected that opts[:head_git_commit_id ] is nil")
        end
        agents = {}
        name_regex = /\/agent\/(.+)/

        if node_commit_id
          repo = ::Grit::Repo.new(agent_repo_dir)
          diffs = repo.diff(node_commit_id, head_git_commit_id, MCAgentPluginDir)

          diffs.each do |diff|
            agent_name = name_regex.match(diff.b_path)[1]
            if diff.deleted_file
              agents[agent_name] = :deleted
            else
              File.open("#{agent_repo_dir}/#{diff.b_path}") { |file| agents[agent_name] = Base64.encode64(file.read) }
            end
          end
        elsif R8::Config[:node_agent_git_clone][:mode] == 'debug'
          node_agent_git_clone_debug_mode_set_agents!(agents)
        else
          agent_paths = Dir.glob("#{agent_repo_dir}/#{MCAgentPluginDir}/*")
          agent_paths.each do |agent_path|
            File.open(agent_path) { |file| agents[name_regex.match(agent_path)[1]] = Base64.encode64(file.read) }
          end
        end

        msg_content = { agent_files: agents }
        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact("pbuilderid",pbuilderid)
        callbacks = context[:callbacks]
        async_agent_call("dev_manager","inject_agent",msg_content,filter,callbacks,context)
      end
      MCAgentPluginDir = "mcollective_additions/plugins/v2.2/agent"

      def self.node_agent_git_clone_debug_mode_set_agents!(agents)
        debug_config = R8::Config[:node_agent_git_clone][:debug_mode]
        begin
          new_files_dir = debug_config[:new_files_dir]
          new_files =
            if debug_config[:new_files]
              debug_config[:new_files].split(';').map{|fn|"#{new_files_dir}/#{fn}"}
            else
              Dir.glob("#{new_files_dir}/*")
            end
          new_files.each do |path|
            file_name = path.split('/').last
            Log.info("Putting in modified file (#{path}) for debug sync agent")
            File.open(path){ |f| agents[file_name] = Base64.encode64(f.read)}
          end
        rescue => e
          Log.error("Trapped error in node_agent_git_clone_debug_mode_set_agents!: #{e}")
        end
      end

      def self.authorize_node(node,callbacks,context_x={})
        repo_user_mh = node.id_handle.createMH(:repo_user)

        node_repo_user = RepoUser.get_matching_repo_user(repo_user_mh, {type: :node}, [:ssh_rsa_private_key,:ssh_rsa_pub_key])

        unless node_repo_user && node_repo_user[:ssh_rsa_private_key]
          raise Error.new("Cannot found ssh private key to authorize nodes")
        end
        unless node_repo_user[:ssh_rsa_pub_key]
          raise Error.new("Cannot found ssh public key to authorize nodes")
        end

        pbuilderid = Node.pbuilderid(node)
        filter = filter_single_fact("pbuilderid",pbuilderid)

        params = {
          agent_ssh_key_public: node_repo_user[:ssh_rsa_pub_key],
          agent_ssh_key_private: node_repo_user[:ssh_rsa_private_key],
          server_ssh_rsa_fingerprint: RepoManager.repo_server_ssh_rsa_fingerprint()
        }
        context = {timeout: DefaultTimeoutAuthNode}.merge(context_x)
        async_agent_call("git_access","add_rsa_info",params,filter,callbacks,context)
      end

      DefaultTimeoutAuthNode = 60

      # TODO: change signature to poll_to_detect_node_ready(node,callbacks,context)
      def self.poll_to_detect_node_ready(node,opts)
        count = opts[:count] || PollCountDefault
        rc = opts[:receiver_context]
        callbacks = {
          on_msg_received: proc do |msg|
            # is_task_canceled is set from participant cancel method
            rc[:callbacks][:on_msg_received].call(msg) unless (node[:is_task_canceled] || node[:is_task_failed])
          end,
          on_timeout: proc do
            if count < 1
              rc[:callbacks][:on_timeout].call
            else
              new_opts = opts.merge(count: count-1)
              poll_to_detect_node_ready(node,new_opts) unless (node[:is_task_canceled] || node[:is_task_failed])
            end
          end
        }

        context = {timeout: opts[:poll_cycle]||PollCycleDefault}.merge(rc)
        pbuilderid = Node.pbuilderid(node)
        filter = filter_single_fact("pbuilderid",pbuilderid)
        params = nil
        async_agent_call("discovery","ping",params,filter,callbacks,context)
      end
      PollCycleDefault = 40
      PollCountDefault = 6

      def self.request__get_logs(task,nodes,callbacks,context)
        log_agent = context[:log_type] && LogAgents[context[:log_type].to_sym]
        raise Error.new("cannot find a mcollective agent to get logs of type #{context[:log_type]||"UNKNOWN"}") unless log_agent
        ret = nodes.inject({}){|h,n|h.merge(n[:id] => nil)}
        key = task[:executable_action_type] ? "task_id" : "top_task_id"
        params = {key: key, value: task.id_handle.get_id().to_s}
        pbuilderids = nodes.map{|n|Node.pbuilderid(n)}
        value_pattern = /^(#{pbuilderids.join('|')})$/
        filter = filter_single_fact("pbuilderid",value_pattern)
        async_context = {expected_count: pbuilderids.size, timeout: GetLogsTimeout}.merge(context)
        async_agent_call(log_agent.to_s,"get",params,filter,callbacks,async_context)
      end
      LogAgents = {
        config_agent: :get_log_fragment
      }
      GetLogsTimeout = 3
      def self.parse_response__get_logs(msg)
        ret = {}
        # TODO: conditionalize on status
        return ret.merge(status: :notok) unless body = msg[:body]
        payload = body[:data]
        ret[:status] = (body[:statuscode] == 0 && payload && payload[:status] == :ok) ? :ok : :notok
        ret[:pbuilderid] = payload && payload[:pbuilderid]
        ret[:log_content] = payload && payload[:data]
        ret
      end

      def self.action_results(result,action)
        if config_agent = config_agent_for_action?(action)
          if config_agent.respond_to?(:action_results)
            config_agent.action_results(result,action)
          else
            Log.error_pp(["Config agent does not have action_results defined:",config_agent])
            nil
          end
        end
      end

      def self.errors_in_node_action_result?(result,action=nil)
        # result[:statuscode] is for mcollective agent errors and data is for errors for agent
        error_type = result[:error_type]||'node agent error'
        if result[:statuscode] != 0
          statusmsg = result[:statusmsg]
          err_msg = (statusmsg ? "#{error_type}: #{statusmsg}" : "#{error_type}")
          [{message: err_msg}]
        else
          payload = result[:data]||{}
          errors_in_node_action_payload?(payload,action)
        end
      end

      private

      def self.config_agent_for_action?(action)
        if config_agent_type = action && action.config_agent_type
          ConfigAgent.load(config_agent_type)
        end
      end

      def self.errors_in_node_action_payload?(payload,action=nil)
        ret = nil
        answer_computed = false
        if config_agent = config_agent_for_action?(action)
          if config_agent.respond_to?(:errors_in_result?)
            answer_computed = true
            ret = config_agent.errors_in_result?(payload,action)
          end
        end
        answer_computed ? ret : errors_in_node_action_payload_default?(payload)
      end

      def self.errors_in_node_action_payload_default?(payload)
        unless [:succeeded,:ok].include?(payload[:status])
          payload[:error] ? [payload[:error]] : (payload[:errors]||[])
        end
      end

      def self.async_agent_call(agent,method,params,filter_x,callbacks,context_x)
        msg = params ? handler.new_request(agent,method,params) : method
        filter = BlankFilter.merge(filter_x).merge("agent" => [agent])
        context = context_x.merge(callbacks: callbacks)
        handler.sendreq_with_callback(msg,agent,context,filter)
      end
      BlankFilter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
      @@handler = nil
      def self.handler
        @@handler ||= Multiplexer.create(Config.mcollective_client())
      end

      def self.filter_single_fact(fact,value,operator=nil)
        {"fact" => [format_fact_filter(fact,value,operator)]}
      end
      def self.format_fact_filter(fact,value,operator=nil)
        if operator.nil?
          operator = value.is_a?(Regexp) ? "=~" : "=="
        end
        if value.is_a?(Regexp)
          value = "/#{value.source}/"
        end
        {fact: fact,value: value.to_s,operator: operator}
      end

      def self.mc_info_for_config_agent(config_agent)
        type = config_agent.type()
        ConfigAgentTypeToMCInfo[type] || raise(Error.new("unexpected config adapter: #{type}"))
      end
      ConfigAgentTypeToMCInfo = {
        puppet: {agent: 'puppet_apply', action: 'run'},
        dtk_provider: {agent: 'action_agent', action: 'run_command'},
        chef: {agent: 'chef_solo', action: 'run'}
      }
    end
  end
end
