require 'mcollective'
require File.expand_path('mcollective/multiplexer', File.dirname(__FILE__))
require File.expand_path('mcollective/monkey_patches', File.dirname(__FILE__))

module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControlNodeConfig
      def self.server_host()
        R8::Config[:command_and_control][:node_config][:mcollective][:host]
      end
      #TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_execution(task_idh,top_task_idh,config_node,opts)
        
        #TODO: getting out implemention info not needed if put module names in component ext refs
        impl_info = get_relevant_impl_info(config_node)
        #TODO: see if this needed stil in that we are pushing at earlier stage
        #push implementation
        version_context = push_implementation(impl_info)

        config_agent = ConfigAgent.load(config_node[:config_agent_type])
        msg_content =  config_agent.ret_msg_content(config_node,impl_info)
        msg_content.merge!(:task_id => task_idh.get_id(),:top_task_id => top_task_idh.get_id(), :version_context => version_context)

        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = filter_single_fact("pbuilderid",pbuilderid)
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        async_agent_call(mcollective_agent(config_agent),"run",msg_content,filter,callbacks,context)
      end

      #TODO: change signature to poll_to_detect_node_ready(node,callbacks,context)
      def self.poll_to_detect_node_ready(node,opts)
        count = opts[:count] || PollCountDefault
        rc = opts[:receiver_context]
        callbacks = {
          :on_msg_received => proc do |msg|
            rc[:callbacks][:on_msg_received].call(msg)
          end,
          :on_timeout => proc do 
            if count < 1
              rc[:callbacks][:on_timeout].call
            else
              new_opts = opts.merge(:count => count-1)
              poll_to_detect_node_ready(node,new_opts)
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
        @@handler ||= MCollectiveMultiplexer.instance
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
      #returns version context, (repo branch pairs)
      def self.get_relevant_impl_info(config_node)
        ret = Array.new
        return ret unless (config_node[:state_change_types] & ["install_component","update_implementation","converge_component","setting"]).size > 0
        sample_idh = config_node[:component_actions].first[:component].id_handle
        impl_idhs = config_node[:component_actions].map{|x|x[:component][:implementation_id]}.uniq.map do |impl_id|
          sample_idh.createIDH(:model_name => :implementation, :id => impl_id)
        end
        Model.get_objs_in_set(impl_idhs,{:col => [:id, :repo, :branch]})
      end
      def self.push_implementation(impl_info)
        #TODO: put in logic to reduce unnecesarry pushes
        ret = Array.new
        impl_info.each do |impl|
          ret << {:repo => impl[:repo],:branch => impl[:branch], :implementation => impl[:display_name]}
          context = {:implementation => impl}
          RepoManager.push_implementation(context)
        end
        ret
      end
    end
  end
end

