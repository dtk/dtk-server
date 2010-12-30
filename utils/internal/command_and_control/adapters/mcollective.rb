require 'mcollective'
include MCollective::RPC

module XYZ
  module CommandAndControlAdapter
    class Mcollective < CommandAndControl
      def dispatch_to_client(action) 
        opts = Options.merge(:filter => Filter.merge("fact"=>[{:value=>pbuilderid(action), :fact=>"pbuilderid"}]))
        mc = rpcclient("chef_client",:options => opts)
        msg_content = {:run_list => ["recipe[user_account]"]}
        results = mc.run(msg_content)
        data = results.map{|result|result.results[:data]} 
        #TODO: where do we do mc.disconnect
        data 
      end
     private
      #TODO: adapters for chef, puppet etc on payload
      def pbuilderid(action)
        action[:node][:external_ref][:instance_id]
      end
      Filter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
      Options = {
        :disctimeout=>4,
        :config=>"/etc/mcollective/client.cfg",
        :filter=> Filter,
        :timeout=>200
      }  
   end
  end
end
