require 'mcollective'
include MCollective::RPC
module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControlNodeConfig
      def self.execute(task_idh,top_task_idh,config_node,attributes_to_set)
        result = nil
        updated_attributes = Array.new
        begin
          config_agent = ConfigAgent.load(config_node[:config_agent_type])
          rpc_client = nil
          Lock.synchronize do
            #TODO: check if really need lock for this
            #deep copy because rpcclient modifies options
            rpc_client = rpcclient(mcollective_agent,:options => Aux::deep_copy(Options))
          end
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
pp [:response,response]
          raise ErrorTimeout.new() unless response
          raise Error.new() unless response[:data]

          result = response[:data]
          raise ErrorFailedResponse.new(result[:status],result[:error]) unless result[:status] == :succeeded 
         ensure
          rpc_client.disconnect() if rpc_client
        end
        [result,updated_attributes]
      end

      def  self.wait_for_node_to_be_ready(node)
        target_identity = nil
        begin
          rpc_client = nil
          Lock.synchronize do
            #TODO: check if need lock for this
            options =   Options.merge(:disctimeout=> 2)
            rpc_client = rpcclient(mcollective_agent,:options => options)
          end
          #looping rather than just one discovery timeout because if node not connecetd msg lost
          count = 0
          while target_identity.nil? and count < 10
            count += 1
            target_identity = ret_discovered_mcollective_id(node,rpc_client)
            sleep 5
          end
        ensure
          rpc_client.disconnect() if rpc_client
        end
        pp [:new_node_target_idenity,target_identity]
        #TODO: want to dleet node too in case timeout problem
        raise ErrorWhileCreatingNode unless target_identity
      end

     private
      def self.mcollective_agent()
        @mcollective_agent ||= R8::Config[:command_and_control][:node_config][:mcollective][:agent]
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
        :disctimeout=>10,
        :config=>"/etc/mcollective/client.cfg",
        :filter=> Filter,
        :timeout=>120
      }  
      Lock = Mutex.new
      def self.push_implementation(config_node,project)
        return unless (config_node[:state_change_types] & ["install_component","update_implementation"]).size > 0
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

######## Monkey patches 
module MCollective
  class Client
    #so discover can exit when get max number of item
    def discover(filter, timeout,opts={})
      begin
        reqid = sendreq("ping", "discovery", filter)
        @log.debug("Waiting #{timeout} seconds for discovery replies to request #{reqid}")

        hosts = []
        Timeout.timeout(timeout) do
          while opts[:max_hosts_count].nil? or opts[:max_hosts_count] > hosts.size
            msg = receive(reqid)
            @log.debug("Got discovery reply from #{msg[:senderid]}")
            hosts << msg[:senderid]
          end
        end
       rescue Timeout::Error => e
        hosts.sort
       rescue Exception => e
        raise
      end
      hosts.sort
    end
    
    #so can in threads have multiple instances of stomp connection
    def initialize(configfile)
      @config = Config.instance
      @config.loadconfig(configfile) unless @config.configured
      @log = Log.instance
      @connection = PluginManager.new_instance("connector_plugin")

      @security = PluginManager["security_plugin"]
      @security.initiated_by = :client

      @options = nil

      @subscriptions = {}
      
      @connection.connect
    end
  end
  
   module PluginManager
     def self.new_instance(plugin)
       raise("No plugin #{plugin} defined") unless @plugins.include?(plugin)

       klass = @plugins[plugin][:class]
       eval("#{klass}.new")
     end
   end
end

