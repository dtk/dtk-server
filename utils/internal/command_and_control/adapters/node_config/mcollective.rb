require 'mcollective'
require File.expand_path('mcollective/multiplexer', File.dirname(__FILE__))
require File.expand_path('mcollective/monkey_patches', File.dirname(__FILE__))

module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControlNodeConfig
      #TODO: change signature to def self.async_execution(task_idh,top_task_idh,config_node,callbacks,context)
      def self.initiate_execution(task_idh,top_task_idh,config_node,opts)
        #push implementation
        project = {:ref => "project1"} #TODO: stub until get the relevant project
        push_implementation(config_node,project)

        config_agent = ConfigAgent.load(config_node[:config_agent_type])
        msg_content =  config_agent.ret_msg_content(config_node)
        msg_content.merge!(:task_id => task_idh.get_id(),:top_task_id => top_task_idh.get_id(), :project => project)

        pbuilderid = Node.pbuilderid(config_node[:node])
        filter = {"fact" => [{:fact=>"pbuilderid",:value=>pbuilderid}]}
        context = opts[:receiver_context]
        callbacks = context[:callbacks]
        async_agent_call(mcollective_agent(),"run",msg_content,filter,callbacks,context)
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
        filter = {"fact" => [{:fact=>"pbuilderid",:value=>pbuilderid}]}
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
        filter = {"fact" => [{:fact=>"pbuilderid", :value=>value_pattern}]}
        async_context = {:expected_count => pbuilderids.size, :timeout => GetLogsTimeout}.merge(context)
        async_agent_call(log_agent.to_s,"get",params,filter,callbacks,async_context)
      end
      LogAgents = {
        :chef => :get_log_fragment
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

      #TODO: not sure if what name of agent is should be configurable; also this is a specfic agent dependent on whetehr chef or puppet
      def self.mcollective_agent()
        @mcollective_agent ||= R8::Config[:command_and_control][:node_config][:mcollective][:agent]
      end

      Lock = Mutex.new
      def self.push_implementation(config_node,project)
        return unless (config_node[:state_change_types] & ["install_component","update_implementation","rerun_component"]).size > 0
        sample_idh = config_node[:component_actions].first[:component].id_handle
        impl_idhs = config_node[:component_actions].map{|x|x[:component][:implementation_id]}.uniq.map do |impl_id|
          sample_idh.createIDH(:model_name => :implementation, :id => impl_id)
        end
        impls = Model.get_objects_in_set_from_sp_hash(impl_idhs,{:col => [:id, :repo]})
        impls.each do |impl|
          context = {:implementation => impl, :project => project}
          Repo.push_implementation(context)
        end
      end
    end
  end
end

