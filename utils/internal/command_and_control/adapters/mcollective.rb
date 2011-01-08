require 'mcollective'
include MCollective::RPC
module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControl
      def self.dispatch_to_client(node_actions)
        config_agent = ConfigAgent.load(node_actions.on_node_config_agent_type)
        rpc_client = nil
        Lock.synchronize do
          #TODO: check if need lock for this
          rpc_client = rpcclient("chef_client",:options => Options)
        end
        target_identity = mcollective_id(node_actions[:node],config_agent,rpc_client)
        unless target_identity
          ret = {
            :status => :failed,
            :error => ErrorCannotFindIdentity.new()
          }
          ret.merge!(:node_name => config_agent.node_name(node_actions[:node])) if node_actions[:node]
          return ret
        end
        msg_content =  config_agent.ret_msg_content(node_actions)
        filter = {"identity" => [target_identity], "agent" => ["chef_client"]}
        results = rpc_client.custom_request("run",msg_content,target_identity,filter)
        rpc_client.disconnect()
        data = results.map{|result|result.results[:data]} 
        data 
      end
     private

      def self.mcollective_id(node,config_agent,rpc_client)
        return nil unless node
        ret_discovered_mcollective_id(node,config_agent,rpc_client)
        ### below removed because quicker failure if use discovery to find if node is up
        #return DiscoveredNodes[node[:id]] if DiscoveredNodes[node[:id]]
        #identity = discover_mcollective_id(node,config_agent)
        #Lock.synchronize{DiscoveredNodes[node[:id]] = identity}
        #identity
      end
      def self.ret_discovered_mcollective_id(node,config_agent,rpc_client)
        pbuilderid = config_agent.pbuilderid(node)
        return nil unless pbuilderid
        filter = Filter.merge("fact" => [{:fact=>"pbuilderid", :value=>pbuilderid}])
        rpc_client.client.discover(filter,Options[:disctimeout],:max_hosts_count => 1).first
      end

      Filter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
      Options = {
        :disctimeout=>10,
        :config=>"/etc/mcollective/client.cfg",
        :filter=> Filter,
        :timeout=>120
      }  
      Lock = Mutex.new
        
      ##removed because quicker failure to use discovery top check node is up
      #DiscoveredNodes = Hash.new
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

