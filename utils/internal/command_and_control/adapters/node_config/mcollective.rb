require 'mcollective'
r8_nested_require('mcollective','monkey_patches')
module DTK
  module CommandAndControlAdapter
    class Mcollective < CommandAndControlNodeConfig
      r8_nested_require('mcollective','assembly_action')
      r8_nested_require('mcollective','multiplexer')
      extend AssemblyActionClassMixin
      def self.server_host()
        R8::Config[:command_and_control][:node_config][:mcollective][:host]
      end
      #TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_execution(task_idh,top_task_idh,config_node,opts)
        version_context = get_version_context(config_node)
        config_agent = ConfigAgent.load(config_node[:config_agent_type])
        msg_content =  config_agent.ret_msg_content(config_node)
        agent_git_details = { :repo => "dtk-node-agent", :branch => "" }
        msg_content.merge!(:task_id => task_idh.get_id(),:top_task_id => top_task_idh.get_id(), :version_context => version_context, :agent_git_details => agent_git_details)
        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact("pbuilderid",pbuilderid)
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        async_agent_call(mcollective_agent(config_agent),"run",msg_content,filter,callbacks,context)
      end

      #TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_cancelation(task_idh,top_task_idh,config_node,opts)
        msg_content = { :task_id => task_idh.get_id(),:top_task_id => top_task_idh.get_id() }
        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact("pbuilderid",pbuilderid)
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        async_agent_call("puppet_cancel","run",msg_content,filter,callbacks,context)
      end

      #TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_sync_agent_code(task_idh,top_task_idh,config_node,opts)
        # TODO Move agent's GIT URL to configuration
        agent_repo_dir = "#{R8::Config[:repo][:base_directory]}/dtk-node-agent"
        agent_paths = Dir.glob("#{agent_repo_dir}/mcollective_additions/plugins/v2.2/agent/*")
        agents = Hash.new
        name_regex = /\/agent\/(.+)/
        agent_paths.each do |agent_path|
          File.open(agent_path) { |file| agents[name_regex.match(agent_path)[1]] = Base64.encode64(file.read) }
        end
        msg_content = { :agent_files => agents }
        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact("pbuilderid",pbuilderid)
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        async_agent_call("dev_manager","inject_agent",msg_content,filter,callbacks,context)
      end

      def self.authorize_node(node,callbacks,context_x={})
        repo_user_mh = node.id_handle.createMH(:repo_user)
        node_repo_user = RepoUser.get_matching_repo_user(repo_user_mh, {:type => :node}, [:ssh_rsa_private_key,:ssh_rsa_pub_key])

        unless node_repo_user and node_repo_user[:ssh_rsa_private_key]
          raise Error.new("Cannot found ssh private key to authorize nodes")
        end
        unless node_repo_user[:ssh_rsa_pub_key]
          raise Error.new("Cannot found ssh public key to authorize nodes")
        end

        pbuilderid = Node.pbuilderid(node)
        filter = filter_single_fact("pbuilderid",pbuilderid)
        params = {
          :agent_ssh_key_public => node_repo_user[:ssh_rsa_pub_key],
          :agent_ssh_key_private => node_repo_user[:ssh_rsa_private_key],
          :server_ssh_rsa_fingerprint => RepoManager.repo_server_ssh_rsa_fingerprint()
        }
        context = {:timeout =>  DefaultTimeoutAuthNode}.merge(context_x)
        async_agent_call("git_access","add_rsa_info",params,filter,callbacks,context)
      end
      DefaultTimeoutAuthNode = 5

      #TODO: change signature to poll_to_detect_node_ready(node,callbacks,context)
      def self.poll_to_detect_node_ready(node,opts)
        count = opts[:count] || PollCountDefault
        rc = opts[:receiver_context]
        callbacks = {
          :on_msg_received => proc do |msg|
            # is_task_canceled is set from participant cancel method
            rc[:callbacks][:on_msg_received].call(msg) unless (node[:is_task_canceled] || node[:is_task_failed])
          end,
          :on_timeout => proc do 
            if count < 1
              rc[:callbacks][:on_timeout].call
            else
              new_opts = opts.merge(:count => count-1)
              poll_to_detect_node_ready(node,new_opts) unless (node[:is_task_canceled] || node[:is_task_failed])
            end
          end
        }
        
        context = {:timeout => opts[:poll_cycle]||PollCycleDefault}.merge(rc)
        pbuilderid = Node.pbuilderid(node)
        filter = filter_single_fact("pbuilderid",pbuilderid)
        params = nil
        async_agent_call("discovery","ping",params,filter,callbacks,context)
      end
      PollCycleDefault = 10
      PollCountDefault = 6

      def self.request__get_logs(task,nodes,callbacks,context)
        log_agent = context[:log_type] && LogAgents[context[:log_type].to_sym]
        raise Error.new("cannot find a mcollective agent to get logs of type #{context[:log_type]||"UNKNOWN"}") unless log_agent
        ret = nodes.inject({}){|h,n|h.merge(n[:id] => nil)}
        key = task[:executable_action_type] ? "task_id" : "top_task_id"
        params = {:key => key, :value => task.id_handle.get_id().to_s}
        pbuilderids = nodes.map{|n|Node.pbuilderid(n)}
        value_pattern = /^(#{pbuilderids.join('|')})$/
        filter = filter_single_fact("pbuilderid",value_pattern)
        async_context = {:expected_count => pbuilderids.size, :timeout => GetLogsTimeout}.merge(context)
        async_agent_call(log_agent.to_s,"get",params,filter,callbacks,async_context)
      end
      LogAgents = {
        :config_agent => :get_log_fragment
      }
      GetLogsTimeout = 3
      def self.parse_response__get_logs(msg)
        ret = Hash.new
        #TODO: conditionalize on status
        return ret.merge(:status => :notok) unless body = msg[:body]
        payload = body[:data]
        ret[:status] = (body[:statuscode] == 0 and payload and payload[:status] == :ok) ? :ok : :notok 
        ret[:pbuilderid] = payload && payload[:pbuilderid]
        ret[:log_content] = payload && payload[:data]
        ret
      end

      def self.async_agent_call(agent,method,params,filter_x,callbacks,context_x)
        msg = params ? handler.new_request(agent,method,params) : method
        filter = BlankFilter.merge(filter_x).merge("agent" => [agent])
        context = context_x.merge(:callbacks => callbacks)
        handler.sendreq_with_callback(msg,agent,context,filter)
      end
      BlankFilter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
      @@handler = nil
      def self.handler()
        @@handler ||= Multiplexer.create(Config.mcollective_client())
      end

      def self.filter_single_fact(fact,value,operator=nil)
        {"fact" => [format_fact_filter(fact,value,operator)]}
      end
      def self.format_fact_filter(fact,value,operator=nil)
        if operator.nil?
          operator = value.kind_of?(Regexp) ? "=~" : "=="
        end
        if value.kind_of?(Regexp)
          value = "/#{value.source}/"
        end
        {:fact=>fact,:value=>value.to_s,:operator=>operator}
      end

      def self.mcollective_agent(config_agent)
        case config_agent.type()
         when :chef then "chef_solo"
         when :puppet then "puppet_apply"
         else raise Error.new("unexpected config adapter")
        end
      end

      Lock = Mutex.new

      def self.get_version_context(config_node)
        include_modules = get_include_modules(config_node)
        impl_info = get_relevant_impl_info(config_node)
        ret = Array.new # using more complicated form rather than straight map becase want it to be a strict array, not DTK array
        impl_info.each do |impl|
          ret << {:repo => impl[:repo],:branch => impl[:branch], :implementation => impl[:module_name]}
        end
        ret
      end

      def self.get_include_modules(config_node)
        component_idhs = config_node[:component_actions].inject(Hash.new) do |h,r|
          cmp = r[:component]
          h.merge(cmp[:id] => cmp.id_handle())
        end.values
        Component::IncludeModule.get_from_component_idhs(component_idhs)
      end

      #returns version context, (repo branch pairs)
      def self.get_relevant_impl_info(config_node)
        ret = Array.new
        return ret unless (config_node[:state_change_types] & ["install_component","update_implementation","converge_component","setting"]).size > 0
        sample_idh = config_node[:component_actions].first[:component].id_handle
        impl_idhs = get_impl_idhs(config_node, sample_idh)
        return ret if impl_idhs.empty?
        Model.get_objs_in_set(impl_idhs,{:col => [:id, :repo, :branch]})
      end

      def self.get_impl_idhs(config_node, sample_idh)
        # if [:node][:implementation_ids_list] empty, or populated use it for getting impl_idhs, 
        # else if nil use gathering from [:component][:implementation_id]
        if impl_ids = config_node[:node][:implementation_ids_list]
          impl_idhs = impl_ids.uniq.map do |impl_id|
            sample_idh.createIDH(:model_name => :implementation, :id => impl_id)
          end
        else
          impl_idhs = config_node[:component_actions].map{|x|x[:component][:implementation_id]}.uniq.map do |impl_id|
            sample_idh.createIDH(:model_name => :implementation, :id => impl_id)
          end
        end
        return impl_idhs
      end

      class Config
        require 'tempfile'
        require 'erubis'
        def self.mcollective_client()
          return @mcollective_client if @mcollective_client
          erubis_content = File.open(File.expand_path("mcollective/client.cfg.erb", File.dirname(__FILE__))).read
          config_file_content = ::Erubis::Eruby.new(erubis_content).result(
           :logfile => logfile(),
           :stomp_host => Mcollective.server_host()
          )
          ret = nil
          #TODO: see if can pass args and not need to use tempfile
          begin
            config_file = Tempfile.new("client.cfg")
            config_file.write(config_file_content)
            config_file.close
            ret = ::MCollective::Client.new(config_file.path)
          ensure
            config_file.unlink
          end
          ret.options = {}
          @mcollective_client = ret
        end
       private
        def self.logfile()
          "/var/log/mcollective/#{Common::Aux.running_process_user()}/client.log"
        end
      end
    end
  end
end

