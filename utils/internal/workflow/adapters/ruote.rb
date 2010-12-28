require 'ruote'
require 'ruote/storage/fs_storage'

module XYZ
  class Ruote < Workflow
    def execute()
      wfid = @engine.launch(@process_def)
      @engine.wait_for(wfid)
    end
   private 
    def initialize(action_list)
      @engine = ::Ruote::Engine.new(::Ruote::Worker.new(::Ruote::FsStorage.new('ruote_work')))
      # registering participants
      @engine.register_participant :chef_client do |workitem|
        begin
          cac = CommandAndControl.create()
          data = cac.dispatch_to_client()
          pp [:data,data]
          workitem.fields['message'] = data 
         rescue Exception => e
          Log.error("error in workflow chef_client: #{e.inspect}")
        end
      end

      @engine.register_participant :bravo do |workitem|
        pp [:bravo,workitem.fields]
      end
      if Action.actions_are_concurrent?(action_list)
        #TODO: stub
        @process_def = ::Ruote.process_definition :name => 'test' do
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

