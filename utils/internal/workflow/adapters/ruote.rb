require 'ruote'
require 'ruote/storage/fs_storage'
#TODO: switch action to node_actions
module XYZ 
  module WorkflowAdapter
    class Ruote < XYZ::Workflow
      def execute()
        wfid = Engine.launch(@process_def)
        Engine.wait_for(wfid)
      end
     private 
      Engine = ::Ruote::Engine.new(::Ruote::Worker.new(::Ruote::FsStorage.new('ruote_work'))) 
      Engine.register_participant :execute_on_node do |workitem|
        begin
          cac = CommandAndControl.create()
          data = cac.dispatch_to_client(workitem.fields["params"]["action"])
          workitem.fields[workitem.fields["params"]["action"]["id"]] = data 
        rescue Exception => e
          Log.error("error in workflow execute_on_node: #{e.inspect}")
        end
      end
      Engine.register_participant :bravo do |workitem|
        pp [:bravo,workitem.fields]
      end
      @@count = 0
     def initialize(ordered_actions)
        @process_def = ret_process_definition(ordered_actions)
      end

      def ret_process_definition(ordered_actions)
        @@count += 1
        ::Ruote.process_definition :name => "process-#{@@count.to_s}" do
          sequence do
            if ordered_actions.is_single_action?()
              participant :ref => :execute_on_node, :action => ordered_actions.single_action()
            elsif ordered_actions.is_concurrent?()
              concurrence :merge_type => :mix do
                ordered_actions.elements.each{|action|participant :ref => :execute_on_node, :action => action}
              end
            elsif ordered_actions.is_sequential?()
              sequence do
                ordered_actions.elements.each{|action|participant :ref => :execute_on_node, :action => action}
              end
            end
            participant :bravo
          end
        end
      end
    end
  end
end
