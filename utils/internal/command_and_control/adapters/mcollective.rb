require 'mcollective'
include MCollective::RPC

module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControl
      #TODO: should take parameter, which includes whether client is chef or puppet
      def dispatch_to_client(action) 
        pp [:client_action,action]
        mc = rpcclient("chef_client",:options => Options)
        msg_content = {:run_list => ["recipe[user_account]"]}
        results =  mc.run(msg_content)
        
        data = results.map{|result|result.results[:data]} 
        mc.disconnect
        data 
      end
     private
      Options = {
        :disctimeout=>2,
        :config=>"/etc/mcollective/client.cfg",
        :filter=>{"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]},
        :timeout=>500000000
      }  
    end
  end
end
