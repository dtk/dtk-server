require 'mcollective'
include MCollective::RPC

module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControl
      def dispatch_to_client(action) 
 #       mc.fact_filter "pbuilderid", pbuilderid(action)
        msg_content = {:run_list => ["recipe[user_account]"]}
        results =  MC.run(msg_content)
        
        data = results.map{|result|result.results[:data]} 
#        mc.disconnect
        data 
      end
     private
      #TODO: adapters for chef, puppet etc on payload
      def pbuilderid(action)
        action[:node][:external_ref][:instance_id]
      end
      Options = {
        :disctimeout=>2,
        :config=>"/etc/mcollective/client.cfg",
        :filter=>{"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]},
        :timeout=>200
      }  
      MC = rpcclient("chef_client",:options => Options)
    end
  end
end
