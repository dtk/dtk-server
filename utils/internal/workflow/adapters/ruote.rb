require 'ruote'
require File.expand_path('ruote/receiver', File.dirname(__FILE__))
require File.expand_path('ruote/poller', File.dirname(__FILE__))

#TODO: switch action to node_actions
module XYZ 
  module WorkflowAdapter
    class Ruote < XYZ::Workflow
      Global = {:foo => :a}
      def execute(top_task_idh=nil)
        @task.update(:status => "executing") #TODO: may handle this by inserting a start subtask
        wfid = Engine.launch(process_def)
        Engine.wait_for(wfid)
      end
     private 
      module Participant
        class Top
          include ::Ruote::LocalParticipant
         private 
          def idh_from_serialized_idh(s_idh)
            IDHandle[s_idh.inject({}){|h,(k,v)|h.merge(k.to_sym => v)}]
          end
        end
        class ExecuteOnNode < Top
          def consume(workitem)
            # _s means getting back in serialized form
            action_s = workitem.fields["params"]["action"]
            top_task_idh_s = workitem.fields["params"]["top_task_idh"]
            task_idh_s = workitem.fields["params"]["task_idh"]

            top_task_idh = idh_from_serialized_idh(top_task_idh_s)
            task = idh_from_serialized_idh(task_idh_s).create_object
            action = action_s #TODO: stub
            result = Workflow.process_executable_action(task,action,top_task_idh)
            workitem.fields[workitem.fields["params"]["action"]["id"]] = result
            reply_to_engine(workitem)
          end
        end
      end

      #TODO: stubbed storage engine using hash store
      Engine = ::Ruote::Engine.new(::Ruote::Worker.new(::Ruote::HashStorage.new))
      Engine.register_participant :execute_on_node, Participant::ExecuteOnNode


      @@count = 0
      def initialize(task)
        super
        @process_def = nil
      end
      
      def process_def()
        @process_def ||= compute_process_def()
      end

      def compute_process_def()
        #TODO: see if we need to leep geenrating new ones or whether we can (delete) and reuse
        @@count += 1
        top_task_idh = @task.id_handle()
        name = "process-#{@@count.to_s}"
        ["define", 
         {"name" => name},
         [compute_process_body(@task,top_task_idh)]]
      end

      def compute_process_body(task,top_task_idh)
        executable_action = task[:executable_action]
        if executable_action
          ["participant", 
           {"ref" => "execute_on_node", 
             "action" => executable_action,
             "task_idh" => task.id_handle,
             "top_task_idh" => top_task_idh
           },
           []]
        elsif task[:temporal_order] == "sequential"
          compute_process_body_sequential(task.subtasks,top_task_idh)
        elsif task[:temporal_order] == "concurrent"
          compute_process_body_concurrent(task.subtasks,top_task_idh)
        else
          Log.error("do not have rules to process task")
        end
      end
      def compute_process_body_sequential(subtasks,top_task_idh)
        ["sequence", {}, subtasks.map{|t|compute_process_body(t,top_task_idh)}]
      end
      def compute_process_body_concurrent(subtasks,top_task_idh)
        ["concurrence", {"merge_type"=>"mix"}, subtasks.map{|t|compute_process_body(t,top_task_idh)}]
      end
    end
  end
end
