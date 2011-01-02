require 'mcollective'
include MCollective::RPC
module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControl
      def self.dispatch_to_client(node_actions,config_agent) 
        identity = mcollective_id(node_actions[:node],config_agent)
        unless identity
          return {
            :status => :failed,
            :node_name => config_agent.node_name(node_actions[:node]), 
            :error => ErrorCannotFindIdentity.new()
          }
        end
        msg_content =  config_agent.ret_msg_content(node_actions)
        filter = {"identity" => [identity], "agent" => ["chef_client"]}
        results = RPCClient.custom_request("run",msg_content,identity,filter)

        data = results.map{|result|result.results[:data]} 
        #TODO: where do we do @mc.disconnect; since @mcs share connection cannot do it here
        data 
      end
     private

      def self.mcollective_id(node,config_agent)
        discover_mcollective_id(node,config_agent)
        ### below removed because quicker failure if use discovery to find if node is up
        #return DiscoveredNodes[node[:id]] if DiscoveredNodes[node[:id]]
        #identity = discover_mcollective_id(node,config_agent)
        #Lock.synchronize{DiscoveredNodes[node[:id]] = identity}
        #identity
      end
      def self.discover_mcollective_id(node,config_agent)
        pbuilderid = config_agent.pbuilderid(node)
        filter = Filter.merge("fact" => [{:fact=>"pbuilderid", :value=>pbuilderid}])
        RPCClient.client.discover(filter,Options[:disctimeout],:max_hosts_count => 1).first
      end

      Filter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
      Options = {
        :disctimeout=>10,
        :config=>"/etc/mcollective/client.cfg",
        :filter=> Filter,
        :timeout=>200
      }  
      RPCClient = rpcclient("chef_client",:options => Options)
      ##removed because quicker failure to use discovery top check node is up
      #DiscoveredNodes = Hash.new
      #Lock = Mutex.new
   end
  end
end

######## Monkey patch so discover can exit when get max number of item
module MCollective
  class Client
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
  end
end
