require 'mcollective'
require File.expand_path('mcollective/multiplexer', File.dirname(__FILE__))
require File.expand_path('mcollective/monkey_patches', File.dirname(__FILE__))
require File.expand_path('mcollective/listener', File.dirname(__FILE__))

include MCollective::RPC

module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControlNodeConfig
      def self.initiate_execution(task_idh,top_task_idh,config_node,opts)
        rpc_client = opts[:connection]
        config_agent = ConfigAgent.load(config_node[:config_agent_type])

        project = {:ref => "project1"} #TODO: stub until get the relevant project

        #push implementation
        push_implementation(config_node,project)

        msg_content =  config_agent.ret_msg_content(config_node)
        msg_content.merge!(:task_id => task_idh.get_id(),:top_task_id => top_task_idh.get_id(), :project => project)

        #make mcollective fire and forget request
        agent = mcollective_agent()
        pbuilderid = pbuilderid(config_node[:node])
        filter = BlankFilter.merge("fact" => [{:fact=>"pbuilderid",:value=>pbuilderid}],"agent" => [agent])
        msg = new_request(agent,"run", msg_content)
        rpc_client.client.r8_sendreq(msg,agent,filter,opts)
      end

      def self.poll_to_detect_node_ready(node,opts)
        count = opts[:count] || PollCountDefault
        rpc_client = opts[:connection]
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
        
        send_opts_rc = {:timeout => opts[:poll_cycle]||PollCycleDefault}.merge(rc).merge(:callbacks => callbacks)
        send_opts = opts.merge(:receiver_context => send_opts_rc)
        pbuilderid = pbuilderid(node)
        filter = BlankFilter.merge("fact" => [{:fact=>"pbuilderid",:value=>pbuilderid}])
        rpc_client.client.r8_sendreq("ping","discovery",filter,send_opts)
      end

      PollCycleDefault = 10
      PollCountDefault = 6

      def self.create_poller_listener_connection()
        ret_rpc_client()
      end

      def self.create_listener(connection)
        McollectiveListener.new(connection)
      end

      def self.get_logs(task,nodes)
        ret = nodes.inject({}){|h,n|h.merge(n[:id] => nil)}
        value = task.id_handle.get_id().to_s
        key = task[:executable_action_type] ? "task_id" : "top_task_id"
        msg_content = {:key => key, :value => value}
        agent = "get_log_fragment"
        handler = MCollectiveMultiplexer.instance
        msg = handler.new_request(agent,"get", msg_content)

        pbuilderids = nodes.map{|n|pbuilderid(n)}
        value_pattern = /^(#{pbuilderids.join('|')})$/
        filter = BlankFilter.merge("fact" => [{:fact=>"pbuilderid", :value=>value_pattern}],"agent" => [agent])
        callbacks = {
          :on_msg_received => proc{|msg|pp [:received,msg]},
          :on_timeout => proc{pp :timeout}
        }
        context = {:callbacks => callbacks, :expected_count => pbuilderids.size, :timeout => 2}
        handler.sendreq_with_callback(msg,agent,context,filter)
        nil
      end

      #TODO: this wil be deprecated
      def self.execute(task_idh,top_task_idh,config_node)
        result = nil
        rpc_client = ret_rpc_client(mcollective_agent) 
        config_agent = ConfigAgent.load(config_node[:config_agent_type])

        target_identity = ret_discovered_mcollective_id(config_node[:node],rpc_client)
        raise ErrorCannotConnect.new() unless target_identity

        project = {:ref => "project1"} #TODO: stub until get the relevant project

        #push implementation
        push_implementation(config_node,project)

        msg_content =  config_agent.ret_msg_content(config_node)
        msg_content.merge!(:task_id => task_idh.get_id(),:top_task_id => top_task_idh.get_id(), :project => project)

        #make mcollective request
        filter = {"identity" => [target_identity], "agent" => [mcollective_agent]}
        response = rpc_client.custom_request("run",msg_content,target_identity,filter).first
        raise ErrorTimeout.new() unless response
        raise Error.new() unless response[:data]
        
        result = response[:data]
        raise ErrorFailedResponse.new(result[:status],result[:error]) unless result[:status] == :succeeded 
        result
      end

     private
      #TODO: patched mcollective fn to put in agent
      #TODO: depracatee
      def self.new_request(agent,action, data)
        callerid = ::MCollective::PluginManager["security_plugin"].callerid
        {:agent  => agent,
          :action => action,
          :caller => callerid,
          :data   => data}
      end

      #using code that puts in own agent 
      def self.ret_rpc_client(agent="all",&block)
        ret = nil
        Lock.synchronize do
          #lock is needed since Client.new is not thread safe
          #deep copy because rpcclient modifies options
          ret = rpcclient(agent,:options => Aux::deep_copy(Options))
        end
        unless block
          ret
        else
          begin
            block.call(ret)
           ensure
            ret.disconnect() if ret
          end
        end
      end


      #TODO: not sure if what name of agent is shoudl be configurable
      def self.mcollective_agent()
        @mcollective_agent ||= R8::Config[:command_and_control][:node_config][:mcollective][:agent]
      end

      def self.ret_discovered_mcollective_ids(pbuilderids,rpc_client)
        ret = Array.new
        return ret if pbuilderids.empty?
        value_pattern = /^(#{pbuilderids.join('|')})$/
        filter = BlankFilter.merge("fact" => [{:fact=>"pbuilderid", :value=>value_pattern}])
        rpc_client.client.discover(filter,Options[:disctimeout],:max_hosts_count => pbuilderids.size)
      end

      def self.ret_discovered_mcollective_id(node,rpc_client)
        return nil unless node
        pbuilderid = pbuilderid(node)
        return nil unless pbuilderid
        filter = BlankFilter.merge("fact" => [{:fact=>"pbuilderid", :value=>pbuilderid}])
        rpc_client.client.discover(filter,Options[:disctimeout],:max_hosts_count => 1).first
      end

      def self.pbuilderid(node)
        (node[:external_ref]||{})[:instance_id]
      end
     
      BlankFilter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
      Options = {
        :disctimeout=>3,
        :config=>"/etc/mcollective/client.cfg",
        :filter=> BlankFilter,
        :timeout=>120
      }  
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

