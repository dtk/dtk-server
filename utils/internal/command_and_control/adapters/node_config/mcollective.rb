require 'mcollective'
include MCollective::RPC
module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControlNodeConfig
      def  self.wait_for_node_to_be_ready(node)
        target_identity = nil
        begin
          rpc_client = nil
          Lock.synchronize do
            #TODO: check if need lock for this
            options =   Options.merge(:disctimeout=> 2)
            rpc_client = rpcclient("chef_client",:options => options)
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

      def self.dispatch_to_client(node_actions)
        ret = nil
        begin
          config_agent = ConfigAgent.load(node_actions.on_node_config_agent_type)
          rpc_client = nil
          Lock.synchronize do
            #TODO: check if need lock for this
            rpc_client = rpcclient("chef_client",:options => Options)
          end
          target_identity = ret_discovered_mcollective_id(node_actions.node,rpc_client)
          raise ErrorCannotConnect.new() unless target_identity

          msg_content =  config_agent.ret_msg_content(node_actions)
          filter = {"identity" => [target_identity], "agent" => ["chef_client"]}
          response = rpc_client.custom_request("run",msg_content,target_identity,filter).first
          raise ErrorTimeout.new() unless response
          raise Error.new() unless response[:data]

          ret = response[:data]
          raise ErrorFailedResponse.new(ret[:status],ret[:error]) unless ret[:status] == :succeeded 
         ensure
          rpc_client.disconnect() if rpc_client
        end
        ret
      end
     private

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

