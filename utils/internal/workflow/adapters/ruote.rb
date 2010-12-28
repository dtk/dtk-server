require 'ruote'
require 'ruote/storage/fs_storage'

module XYZ 
  module WorkflowAdapter
    class Ruote < XYZ::Workflow
      def execute()
        wfid = @engine.launch(@process_def)
        @engine.wait_for(wfid)
      end
     private 
      def initialize(ordered_actions)
        @engine = ::Ruote::Engine.new(::Ruote::Worker.new(::Ruote::FsStorage.new('ruote_work')))
        # registering participants
        @engine.register_participant :execute_on_node do |workitem|
          begin
            cac = CommandAndControl.create()
            data = cac.dispatch_to_client()
            pp [:data,data]
            workitem.fields['message'] = data 
           rescue Exception => e
            Log.error("error in workflow execute_on_node: #{e.inspect}")
          end
        end
        
        @engine.register_participant :bravo do |workitem|
          pp [:bravo,workitem.fields]
        end
        @process_def = ret_process_definition(ordered_actions)
      end

      def ret_process_definition(ordered_actions)
          #TODO: stub
        ::Ruote.process_definition :name => 'test' do
          sequence do
            participant :execute_on_node
            participant :execute_on_node
            participant :bravo
          end
        end
      end
    end
  end
end
