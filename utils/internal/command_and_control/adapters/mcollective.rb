require 'mcollective'
include MCollective::RPC
module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControl
      def initialize()  
        @mc = rpcclient("chef_client",:options => Options)
      end
      def dispatch_to_client(node_actions) 
        config_agent = ConfigAgent.load(node_actions.config_agent_type)
        identity = mcollective_id(node_actions[:node],config_agent)
        unless identity
          Log.error("cannot find identity for node #{node_actions[:node].inspect}")
          return nil
        end
        msg_content = config_agent.ret_msg_content(node_actions)
        filter = {"identity" => [identity], "agent" => ["chef_client"]}
        results = @mc.custom_request("run",msg_content,identity,filter)
        data = results.map{|result|result.results[:data]} 
        #TODO: where do we do @mc.disconnect; since @mcs shaer connection cannot do it here
        data 
      end
     private

      def mcollective_id(node,config_agent)
        return DiscoveredNodes[node[:id]] if DiscoveredNodes[node[:id]]
        identity = discover_mcollective_id(node,config_agent)
        Lock.synchronize{DiscoveredNodes[node[:id]] = identity}
        identity
      end
      def discover_mcollective_id(node,config_agent)
        pbuilderid = config_agent.pbuilderid(node)
        filter = Filter.merge("fact" => [{:fact=>"pbuilderid", :value=>pbuilderid}])
        @mc.client.discover(filter,Options[:disctimeout]).first
      end

      Filter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
      Options = {
        :disctimeout=>2,
        :config=>"/etc/mcollective/client.cfg",
        :filter=> Filter,
        :timeout=>200
      }  
      DiscoveredNodes = Hash.new
      Lock = Mutex.new
   end
  end
end
