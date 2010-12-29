require 'mcollective'
include MCollective::RPC

module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControl
      def dispatch_to_client(action) 
         msg_content = {:run_list => ["recipe[user_account]"]}
        results =  MC.run(msg_content)
        
        data = results.map{|result|result.results[:data]} 
#        mc.disconnect
        data 
      end
     private
      Options = {
        :disctimeout=>2,
        :config=>"/etc/mcollective/client.cfg",
        :filter=>{"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]},
        :timeout=>500000000
      }  
      MC = rpcclient("chef_client",:options => Options)
    end
  end
end
