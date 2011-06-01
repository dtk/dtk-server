require 'ruote'
require File.expand_path('ruote/common', File.dirname(__FILE__))
require File.expand_path('ruote/receiver', File.dirname(__FILE__))
require File.expand_path('ruote/poller', File.dirname(__FILE__))

#TODO: switch action to node_actions
module XYZ 
  module WorkflowAdapter
    class Ruote < XYZ::Workflow
      #TODO: need to clean up whether engine is persistent; whether execute can be called more than once for any insatnce
      def execute(top_task_idh=nil)
        @task.update(:status => "executing") #TODO: may handle this by inserting a start subtask
        #TODO: may want to only create connection, poller and receiver on demand (if task needs it)
        begin
          @connection = CommandAndControl.create_poller_listener_connection()
          listener = CommandAndControl.create_listener(@connection)
          @receiver = RuoteReceiver.new(Engine,listener)
          @poller = RuotePoller.new(@connection,@receiver)
          wfid = Engine.launch(process_def())
          Engine.wait_for(wfid)
         rescue Exception => e
          raise e
         ensure
          @poller.stop if @poller
          @receiver.stop if @receiver
          @connection.disconnect() if @connection
        end
        nil
      end
      attr_reader :listener,:poller
     private 
      def initialize()
        super
        @connection = nil
        @receiver = nil
        @poller = nil
      end

      ObjectStore = Hash.new
      ObjectStoreLock = Mutex.new
      #TODO: make sure task id is globally unique
      def self.push_on_object_store(task_id,task_info)
        ObjectStoreLock.synchronize{ObjectStore[task_id] = task_info}
      end
      
      module Participant
        class Top
          include ::Ruote::LocalParticipant
         private 
          def get_and_delete_from_object_store(task_id)
            ret = nil
            ObjectStoreLock.synchronize{ret = ObjectStore.delete(task_id)}
            ret
          end
        end
        class ExecuteOnNode < Top
          def consume(workitem)
            task_id = workitem.fields["params"]["task_id"]
            task_info = get_and_delete_from_object_store(task_id)
            action = task_info["action"]
            top_task_idh = task_info["top_task_idh"]
            workflow = task_info["workflow"]
            if action.long_running?
              context = RuoteReceiverContext.new(workitem,{:expected_count => 1})
              workflow.initiate_executable_action(action,top_task_idh,context)
            else
              result = process_executable_action(action,top_task_idh)
              workitem.fields[workitem.fields["params"]["action"]["id"]] = result
              reply_to_engine(workitem)
            end
          end
        end

        class EndOfTask < Top
          def consume(workitem)
            pp workitem.fields
            reply_to_engine(workitem)
          end
        end
      end

      #TODO: stubbed storage engine using hash store
      Engine = ::Ruote::Engine.new(::Ruote::Worker.new(::Ruote::HashStorage.new))
      Engine.register_participant :execute_on_node, Participant::ExecuteOnNode
      Engine.register_participant :end_of_task, Participant::EndOfTask


      @@count = 0
      def initialize(task)
        super
        @process_def = nil
      end
      
      def process_def()
        @process_def ||= compute_process_def()
      end

      def compute_process_def()
        #TODO: see if we need to keep generating new ones or whether we can (delete) and reuse
        @@count += 1
        top_task_idh = @task.id_handle()
        name = "process-#{@@count.to_s}"
        ["define", 
         {"name" => name},
         [["sequence", {}, 
          [compute_process_body(@task,top_task_idh),
           ["participant",{"ref" => "end_of_task"},[]]]]]]
      end

      def compute_process_body(task,top_task_idh)
        executable_action = task[:executable_action]
        if executable_action
          task_info = {
            "action" => executable_action,
            "workflow" => self,
            "top_task_idh" => top_task_idh
          }
          task_id = task.id()
          Ruote.push_on_object_store(task_id,task_info)

          ["participant", 
           {"ref" => "execute_on_node", 
            "task_id" => task_id,
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
        ["concurrence", {"merge_type"=>"stack"}, subtasks.map{|t|compute_process_body(t,top_task_idh)}]
      end
    end
  end
end
