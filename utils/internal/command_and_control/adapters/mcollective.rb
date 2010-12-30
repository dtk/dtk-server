require 'mcollective'
include MCollective::RPC
module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControl
      def initialize()  
        @mc = rpcclient("chef_client",:options => Options)
      end
      def dispatch_to_client(action) 
        identity = mcollective_id(action[:node])
        unless identity
          Log.error("cannot find identity for node #{action[:node].inspect}")
          return nil
        end
        msg_content = {:run_list => ["recipe[user_account]"]}
        filter = {"identity" => [identity], "agent" => ["chef_client"]}
        results = @mc.custom_request("run",msg_content,identity,filter)
        data = results.map{|result|result.results[:data]} 
        #TODO: where do we do @mc.disconnect; since @mcs shaer connection cannot do it here
        data 
      end
     private

      def mcollective_id(node)
        return DiscoveredNodes[node[:id]] if DiscoveredNodes[node[:id]]
        identity = discover_mcollective_id(node)
        Lock.synchronize{DiscoveredNodes[node[:id]] = identity}
        identity
      end
      def discover_mcollective_id(node)
        filter = Filter.merge("fact" => [{:fact=>"pbuilderid", :value=>pbuilderid(node)}])
        @mc.client.discover(filter,Options[:disctimeout]).first
      end

      #TODO: adapters for chef, puppet etc on payload
      def pbuilderid(node)
        node[:external_ref][:instance_id]
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
