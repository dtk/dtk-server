require 'mcollective'
require File.expand_path('mcollective/monkey_patches', File.dirname(__FILE__))
require File.expand_path('mcollective/listener', File.dirname(__FILE__))
require File.expand_path('mcollective/poller', File.dirname(__FILE__))

include MCollective::RPC

module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControlNodeConfig
      def self.initiate_execution(task_idh,top_task_idh,config_node,attributes_to_set,opts)
        rpc_client = opts[:connection]
        updated_attributes = Array.new
        config_agent = ConfigAgent.load(config_node[:config_agent_type])

        target_identity = ret_discovered_mcollective_id(config_node[:node],rpc_client)
        raise ErrorCannotConnect.new() unless target_identity

        project = {:ref => "project1"} #TODO: stub until get the relevant project

        #push implementation
        push_implementation(config_node,project)

        msg_content =  config_agent.ret_msg_content(config_node)
        msg_content.merge!(:task_id => task_idh.get_id(),:top_task_id => top_task_idh.get_id(), :project => project)

        #make mcollective fire and forget request
        agent = mcollective_agent()
        filter = {"identity" => [target_identity], "agent" => [agent]}
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
        
        send_opts_rc = rc.merge(:callbacks => callbacks)
        send_opts = opts.merge(:receiver_context => send_opts_rc, :timeout => PollLengthDefault)
        pbuilderid = pbuilderid(node)
        filter = Filter.merge("fact" => [{:fact=>"pbuilderid",:value=>pbuilderid}])
        rpc_client.client.r8_sendreq("ping","discovery",filter,send_opts)
      end

      PollLengthDefault = 10
      PollCountDefault = 10

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
        rpc_client = ret_rpc_client(agent) 
        pbuilderid_index = nodes.inject({}){|h,n|h.merge(pbuilderid(n) => n[:id])}
        target_identities = ret_discovered_mcollective_ids(pbuilderid_index.keys,rpc_client)
        unless target_identities.empty?
          filter = {"identity" => /^(#{target_identities.join('|')})$/}
          responses = rpc_client.custom_request("get",msg_content,target_identities,filter)
          raise ErrorTimeout.new() unless responses #TODO: is this needed?
          responses.each do |response|
            node_id = pbuilderid_index[response[:data][:pbuilderid]]
            ret[node_id] = response[:data]
          end
        end
        ret
      end

      #TODO: this wil be deprecated
      def self.execute(task_idh,top_task_idh,config_node,attributes_to_set)
        result = nil
        updated_attributes = Array.new
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
        [result,updated_attributes]
      end

      #TODO: this wil be deprecated
      def  self.wait_for_node_to_be_ready(node)
        pp [:test1,node[:display_name]]
        target_identity = nil
        #looping rather than just one discovery timeout because if node not connecetd msg lost
        count = 0
        while target_identity.nil? and count < 10
          pp [:test2,node[:display_name]]
          count += 1
          rpc_client = nil
          rpc_opts =   Options.merge(:disctimeout=> 2)

          begin
            #creating and detsroying rpcclient in loop because when kept open looks liek blocking thread scheduling
            Lock.synchronize do
              #lock is needed since Client.new is not thread safe
              rpc_client = rpcclient(mcollective_agent,:options => rpc_opts)
            end
            target_identity = ret_discovered_mcollective_id(node,rpc_client)
           ensure
            rpc_client.disconnect() if rpc_client
          end
          sleep 5
        end
        pp [:new_node_target_identity,target_identity]
        #TODO: want to delete node too in case timeout problem
        raise ErrorWhileCreatingNode unless target_identity
      end

     private
      #TODO: patched mcollective fn to put in agent
      def self.new_request(agent,action, data)
        callerid = ::MCollective::PluginManager["security_plugin"].callerid
        {:agent  => agent,
          :action => action,
          :caller => callerid,
          :data   => data}
      end

      #using code that puts in own agent 
      def self.ret_rpc_client(agent="all")
        ret = nil
        Lock.synchronize do
          #lock is needed since Client.new is not thread safe
          #deep copy because rpcclient modifies options
          ret = rpcclient(agent,:options => Aux::deep_copy(Options))
        end
        ret
      end

      #TODO: not sure if what name of agent is shoudl be configurable
      def self.mcollective_agent()
        @mcollective_agent ||= R8::Config[:command_and_control][:node_config][:mcollective][:agent]
      end

      def self.ret_discovered_mcollective_ids(pbuilderids,rpc_client)
        ret = Array.new
        return ret if pbuilderids.empty?
        value_pattern = /^(#{pbuilderids.join('|')})$/
        filter = Filter.merge("fact" => [{:fact=>"pbuilderid", :value=>value_pattern}])
        rpc_client.client.discover(filter,Options[:disctimeout],:max_hosts_count => pbuilderids.size)
      end

      def self.ret_discovered_mcollective_id(node,rpc_client)
        return nil unless node
        pbuilderid = pbuilderid(node)
        return nil unless pbuilderid
        filter = Filter.merge("fact" => [{:fact=>"pbuilderid", :value=>pbuilderid}])
        rpc_client.client.discover(filter,Options[:disctimeout],:max_hosts_count => 1).first
      end

      def self.pbuilderid(node)
        (node[:external_ref]||{})[:instance_id]
      end
     
      Filter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
      Options = {
        :disctimeout=>3,
        :config=>"/etc/mcollective/client.cfg",
        :filter=> Filter,
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

