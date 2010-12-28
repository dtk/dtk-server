module XYZ
  class Workflow
    def self.create_workflow(action_list)
      self.new(action_list)
    end
    def execute()
    end
    def initialize(action_list)
    end
  end
end
=begin
require 'ruote'
require 'ruote/storage/fs_storage'

#TODO: encapsulate mcollective
require 'mcollective'
include MCollective::RPC

module XYZ
  class Workflow
    def self.create_workflow(action_list)
      self.new(action_list)
    end
    def execute()
      wfid = @engine.launch(@process_def)
      @engine.wait_for(wfid)
    end
   private 
    MCOptions = {
      :disctimeout=>2,
      :config=>"/etc/mcollective/client.cfg",
      :filter=>{"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]},
      :timeout=>500000000
    }  
    def initialize(action_list)
      @engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::FsStorage.new('ruote_work')))
      
      # registering participants
      @engine.register_participant :chef_client do |workitem|
        mc = rpcclient("chef_client",:options => MCOptions)
        msg_content = {:run_list => ["recipe[user_account]"]}
        results =  mc.run(msg_content)
        data = results.map{|result|result.results[:data]} #.first.results[:data]}
        mc.disconnect
        pp [:data,data]
        workitem.fields['message'] = data 
      end

      @engine.register_participant :bravo do |workitem|
        pp [:bravo,workitem.fields]
      end
      if Action.actions_are_concurrent?(action_list)
        #TODO: stub
        @process_def = Ruote.process_definition :name => 'test' do
          sequence do
            participant :chef_client
            participant :chef_client
            participant :bravo
          end
        end
      end
    end
  end
end
=end
