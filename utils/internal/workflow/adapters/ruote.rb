require 'ruote'
require File.expand_path('ruote/receiver', File.dirname(__FILE__))
require File.expand_path('ruote/generate_process_defs', File.dirname(__FILE__))

module XYZ 
  module WorkflowAdapter
    class Ruote < XYZ::Workflow
      include RuoteGenerateProcessDefs
      def execute(top_task_idh=nil)
        @task.update(:status => "executing") #TODO: may handle this by inserting a start subtask
        TaskInfo.initialize_task_info()
        begin
          @connection = CommandAndControl.create_poller_listener_connection()
          listener = CommandAndControl.create_listener(@connection)
          @receiver = RuoteReceiver.new(Engine,listener)
          wfid = Engine.launch(process_def())
          Engine.wait_for(wfid)
          
          #detect if wait for finished due to normal execution or errors 
          errors = Engine.errors(wfid)
          unless errors
            pp :normal_completion
          else
            pp ["intercepted errors:", errors.map{|e|e.message}] 
            #different ways to continue
            # one way is "fix error " ; engine.replay_at_error(err); engine.wait_for(wfid)

            #this is suppose to kill everything
            #TODO: doe snot seem to work
            Engine.cancel_process(wfid)
          end
         rescue Exception => e
          pp "error trap in ruore#execute"
          pp [e,e.backtrace[0..3]]
         ensure
          @receiver.stop if @receiver
          @connection.disconnect() if @connection
          TaskInfo.clean
        end
        nil
      end

      attr_reader :listener
     private 
      def initialize(task)
        super(task)
        @process_def = nil
        @connection = nil
        @receiver = nil
      end
      def process_def()
        @process_def ||= compute_process_def(task)
        @process_def #TODO: just for testing so can checkpoint and see what it looks like
      end

      #TODO: stubbed storage engine using hash store; look at alternatives like redis and
      #running with remote worker
      Engine = ::Ruote::Engine.new(::Ruote::Worker.new(::Ruote::HashStorage.new))

      class TaskInfo 
        @@count = 0
        Store = Hash.new
        Lock = Mutex.new
        def self.initialize_task_info()
          Store[@@count] = Hash.new
        end
        def self.set(task_id,task_info,task_type=nil)
          key = task_key(task_id,task_type)
          Lock.synchronize{Store[@@count][key] = task_info}
        end
        def self.get_and_delete(task_id,task_type=nil)
          key = task_key(task_id,task_type)
          ret = nil
          Lock.synchronize{ret = Store[@@count].delete(key)}
          ret 
        end
        def self.clean()
          Lock.synchronize{Store[@@count] = nil} 
          @@count += 1
        end
       private
        def self.task_key(task_id,task_type)
          task_type ? "#{task_id.to_s}-#{task_type}" : task_id.to_s
        end
      end

      module Participant
        class Top
          include ::Ruote::LocalParticipant
          def initialize(opts=nil)
            @opts = opts
          end
          def task_id(workitem)
            workitem.params["task_id"]
          end
          def get_and_delete_task_info(workitem)
            params = workitem.params
            TaskInfo.get_and_delete(params["task_id"],params["task_type"])
          end
        end

        class DetectNodeIsReady < Top
          def consume(workitem)
            task_id = task_id(workitem)
            task_info = get_and_delete_task_info(workitem)
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
            task_id = task_id(workitem)
            task_info = get_and_delete_task_info(workitem)
            action = task_info["action"]
            top_task_idh = task_info["top_task_idh"]
            workflow = task_info["workflow"]
            begin
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
                workflow.initiate_executable_action(action,top_task_idh,context)
              else
                result = workflow.process_executable_action(action,top_task_idh)
                workitem.fields["result"] = result
                reply_to_engine(workitem)
              end
             rescue Exception => e
#TODO: figuring best way to handle errors
raise e
=begin
              workitem.fields["result"] = {"status" =>"failed"}
              reply_to_engine(workitem)
=end
            end
          end

          #TODO: need to turn threading off for now because if dont can have two threads 
          #eat ech others messages; may solve with existing mechism or go straight to
          #using stomp event machine
          #may even not be necessary to thread the consume since very fast
          def do_not_thread
            true
          end
        end

        class EndOfTask < Top
          def consume(workitem)
            pp [workitem.fields,workitem.params]
            reply_to_engine(workitem)
          end

        end
        class DebugTask < Top
          def consume(workitem)
            s = 15
            pp "debug task sleep for #{s.to_s} seconds" 
            sleep s
            pp "debug task finished"
            reply_to_engine(workitem)
          end
        end
      end

      Participants = Array.new
      %w{ExecuteOnNode EndOfTask DetectNodeIsReady DebugTask}.each do |w|
        participant = Aux.underscore(w).to_sym
        Participants << participant
        Engine.register_participant participant, Participant.const_get(w)
      end
    end
  end
end
