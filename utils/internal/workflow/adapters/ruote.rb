require 'ruote'
require File.expand_path('ruote/receiver', File.dirname(__FILE__))
require File.expand_path('ruote/generate_process_defs', File.dirname(__FILE__))

#TODO: switch action to node_actions
module XYZ 
  module WorkflowAdapter
    class Ruote < XYZ::Workflow
      include RuoteGenerateProcessDefs
      #TODO: need to clean up whether engine is persistent; whether execute can be called more than once for any insatnce
      def execute(top_task_idh=nil)
        @task.update(:status => "executing") #TODO: may handle this by inserting a start subtask
        begin
          #TODO: running into problem multiple times; dont know yet whetehr race condition max conditions
          #or even lack of patch I had put in 1.1 that is no taken out
          @connection = CommandAndControl.create_poller_listener_connection()
          listener = CommandAndControl.create_listener(@connection)
          @receiver = RuoteReceiver.new(Engine,listener)
          wfid = Engine.launch(process_def())
          Engine.wait_for(wfid)
         rescue Exception => e
          pp [e,e.backtrace[0..3]]
          raise e
         ensure
        end
        nil
      end

      def shutdown_defer_context()
        @receiver.stop if @receiver
        @connection.disconnect() if @connection
      end

      attr_reader :listener
     private 
      def initialize()
        super
        @connection = nil
        @receiver = nil
      end

      ObjectStore = Hash.new
      ObjectStoreLock = Mutex.new
      #TODO: make sure task id is globally unique
      def self.push_on_object_store(task_key_x,task_info)
        task_key = task_key_x.to_s
        ObjectStoreLock.synchronize{ObjectStore[task_key] = task_info}
      end
      
      module Participant
        class Top
          include ::Ruote::LocalParticipant
         private 
          def get_and_delete_from_object_store(task_key_x)
            task_key = task_key_x.to_s
            ret = nil
            ObjectStoreLock.synchronize{ret = ObjectStore.delete(task_key)}
            ret
          end
        end

        class DetectNodeReady < Top
          def consume(workitem)
            task_id = workitem.fields["params"]["task_id"]
            task_info = get_and_delete_from_object_store(task_id)
            action = task_info["action"]
            workflow = task_info["workflow"]
            callbacks = {
              :on_msg_received => proc do |msg|
                pp [:found,msg[:senderid]]
                self.reply_to_engine(workitem)
              end,
              :on_timeout => proc do 
                pp [:timeout]
                self.reply_to_engine(workitem)
              end
            }
            context = {:callbacks => callbacks, :expected_count => 1}
            workflow.poll_to_detect_node_ready(action[:node],context)
          end
        end
        class ExecuteOnNode < Top
          LockforDebug = Mutex.new
          def consume(workitem)
            #LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
            task_id = workitem.fields["params"]["task_id"]
            task_info = get_and_delete_from_object_store(task_id)
            action = task_info["action"]
            top_task_idh = task_info["top_task_idh"]
            workflow = task_info["workflow"]
            if action.long_running?
              callbacks = {
                :on_msg_received => proc do |msg|
                  workitem.fields["result"] = msg[:body].merge("task_id" => workitem.params["task_id"])
                  self.reply_to_engine(workitem)
                end,
                :on_timeout => proc do 
                  workitem.fields["result"] = {
                    "status" => "timeout", 
                    "task_id" => workitem.params["task_id"]}
                  self.reply_to_engine(workitem)
                end
              }
              context = {:callbacks => callbacks, :expected_count => 1}
              begin
                #TODO: need to cleanup mechanism below that has receivers waiting for
                #to get id back because since tehy share a connection tehy can eat each others replys
                #think best solution is using async receiver; otherwise will need for them to create and destroy 
                #their own connections
                workflow.initiate_executable_action(action,top_task_idh,context)
                #TODO: fix up how to best pass action state
               rescue CommandAndControl::ErrorCannotConnect
                workitem.fields["result"] = {"status" =>"failed", "error" => "cannot_connect"}  
                reply_to_engine(workitem)
               rescue Exception => e
                pp e.backtrace[0..5]
                workitem.fields["result"] = {"status" =>"failed"}
                reply_to_engine(workitem)
              end
            else
              result = process_executable_action(action,top_task_idh)
              workitem.fields[workitem.fields["params"]["action"]["id"]] = result
              reply_to_engine(workitem)
            end
          end
=begin
#TODO: experimenting with turning this on and off
          def do_not_thread
            true
          end
=end

        end

        class EndOfTask < Top
          def consume(workitem)
            pp [workitem.fields,workitem.params]
            reply_to_engine(workitem)
          end
        end
      end

      #TODO: stubbed storage engine using hash store; look at alternatives like redis and
      #running with remote worker
      Engine = ::Ruote::Engine.new(::Ruote::Worker.new(::Ruote::HashStorage.new))
      %w{ExecuteOnNode EndOfTask DetectNodeReady}.each do |w|
        Engine.register_participant Aux.underscore(w), Participant.const_get(w)
      end

      def initialize(task)
        super
        @process_def = nil
      end
      
      def process_def()
        @process_def ||= compute_process_def()
      end

    end
  end
end
