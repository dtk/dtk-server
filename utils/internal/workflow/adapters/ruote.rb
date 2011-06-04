require 'ruote'
require File.expand_path('ruote/receiver', File.dirname(__FILE__))
require File.expand_path('ruote/generate_process_defs', File.dirname(__FILE__))

module XYZ 
  module WorkflowAdapter
    class Ruote < XYZ::Workflow
      include RuoteGenerateProcessDefs
      def execute(top_task_idh=nil)
        @task.update(:status => "executing") 
        TaskInfo.initialize_task_info()
        begin
          @connection = CommandAndControl.create_poller_listener_connection()
          listener = CommandAndControl.create_listener(@connection)
          @receiver = RuoteReceiver.new(Engine,listener)
          wfid = Engine.launch(process_def())
          Engine.wait_for(wfid)
          
          #detect if wait for finished due to normal execution or errors 
          errors = Engine.errors(wfid)
          if errors.nil? or errors.empty?
            pp :normal_completion
          else
            p "intercepted errors:"
            errors.each  do |e|
              p e.message
              depth = 5
              e.trace.each do |l|
                p l.chomp
                depth -= 1
                break if depth < 0
              end
              pp "----------------"
            end

            #different ways to continue
            # one way is "fix error " ; engine.replay_at_error(err); engine.wait_for(wfid)

            #this cancels everything
            Engine.cancel_process(wfid)
          end
         rescue Exception => e
          pp "error trap in ruote#execute"
          pp [e,e.backtrace[0..3]]
         ensure
          @receiver.stop if @receiver
          @connection.disconnect() if @connection
          TaskInfo.clean
        end
        nil
      end
      
      def initiate_executable_action(action,top_task_idh,receiver_context)
        opts = {
          :initiate_only => true,
          :connection => @connection,
          :receiver => @receiver,
          :receiver_context => receiver_context
        }
        CommandAndControl.execute_task_action(action,@task,top_task_idh,opts)
      end

      def poll_to_detect_node_ready(node,receiver_context,opts={})
        poll_opts = opts.merge({
          :connection => @connection, 
          :receiver => @receiver,
          :receiver_context => receiver_context})
        CommandAndControl.poll_to_detect_node_ready(node,poll_opts)
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

          def set_result_succeeded(workitem,new_result,task)
            update_hash = {
              :status => "succeeded",
              :result => TaskAction::Result::Succeeded.new(new_result)
            }             
            task.update(update_hash)
            #TODO: for testing removing so can rerun executable_action.update_state_change_status(task.model_handle,:completed)  #this send pending changes' states
          end

          def set_result_timeout(workitem,new_result,task)
            #TODO: what should be set here; is no op fine
          end

         private
          #TODO: may deprecate if not needing to update ruote fields with result
          #if use must cooridntae with concurrence merge type
          def set_result__stack(workitem,new_result)
            prev = workitem.fields["result"] || (workitem.fields["stack"] && workitem.fields["stack"].map{|x|x["result"]}) 
            workitem.fields["result"] = prev ?
              (prev.kind_of?(Hash) ? [prev,new_result] : prev + [new_result]) :
              new_result
          end
        end

        class DetectCreatedNodeIsReady < Top
          def consume(workitem)
            task_info = get_and_delete_task_info(workitem)
            workflow = task_info["workflow"]
            action = task_info["action"]
            callbacks = {
              :on_msg_received => proc do |msg|
                pp [:found,msg[:senderid]]
                #TODO: put in updating and propagating task attributes
                self.reply_to_engine(workitem)
              end,
              :on_timeout => proc do 
                pp [:timeout]
                self.reply_to_engine(workitem)
              end
            }
            num_poll_cycles = 10
            poll_cycle = 6
            context = {:callbacks => callbacks, :expected_count => 1,:count => num_poll_cycles,:poll_cycle => poll_cycle} 
            workflow.poll_to_detect_node_ready(action[:node],context)
          end
        end

        class DetectIfNodeIsResponding < Top
          def consume(workitem)
            task_info = get_and_delete_task_info(workitem)
            workflow = task_info["workflow"]
            action = task_info["action"]
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
            poll_cycle = 2
            context = {:callbacks => callbacks, :expected_count => 1,:count => 1,:poll_cycle => poll_cycle} 
            workflow.poll_to_detect_node_ready(action[:node],context)
          end
        end
        class ExecuteOnNode < Top
          #LockforDebug = Mutex.new
          def consume(workitem)
            #LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
            task_id = task_id(workitem)
            task_info = get_and_delete_task_info(workitem)
            action = task_info["action"]
            top_task_idh = task_info["top_task_idh"]
            workflow = task_info["workflow"]
            task = workflow.task

            execution_context(task,top_task_idh) do
              if action.long_running?
                callbacks = {
                  :on_msg_received => proc do |msg|
                    result = msg[:body].merge("task_id" => task_id)
                    set_result_succeeded(workitem,result,task)
                    self.reply_to_engine(workitem)
                  end,
                  :on_timeout => proc do 
                    result = {
                      "status" => "timeout", 
                      "task_id" => task_id}
                    set_result_timeout(workitem,result,task)
                    self.reply_to_engine(workitem)
                  end
                }
                receiver_context = {:callbacks => callbacks, :expected_count => 1}
                workflow.initiate_executable_action(action,top_task_idh,receiver_context)
              else
                result = workflow.process_executable_action(action,top_task_idh)
                set_result_succeeded(workitem,result,task)
                reply_to_engine(workitem)
              end
            end
          end

          def execution_context(task,top_task_idh,&body)
            debug_print_task_info = "task_id=#{task.id.to_s}; top_task_id=#{top_task_idh.get_id()}"
            begin
              yield
             rescue CommandAndControl::Error => e
              update_hash = {
                :status => "failed",
                :result => TaskAction::Result::Failed.new(e)
              }
              task.update(update_hash)
              pp [:task_failed,debug_print_task_info,e]
              raise e
            rescue Exception => e
              update_hash = {
                :status => "failed",
                :result => TaskAction::Result::Failed.new(CommandAndControl::Error.new)
              }
              task.update(update_hash)
              pp [:task_failed_internal_error,debug_print_task_info,e,e.backtrace[0..7]]
              raise e
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
            count = 15
            pp "debug task sleep for #{s.to_s} seconds" 
            @is_on = true
            while @is_on and count > 0
              sleep 1
              count -= 1
            end
            pp "debug task finished"
            reply_to_engine(workitem)
          end
          def cancel(fei, flavour)
            pp "cancel called on debug task"
            p @is_on
            @is_on = false
          end
        end

        #register all the classes
        List = Array.new
        ObjectSpace.each_object(Module) do |m|
          next unless m.ancestors.include? Participant::Top and  m != Top
          participant = Aux.underscore(Aux.demodulize(m.to_s)).to_sym
          List << participant
          Engine.register_participant participant, m
        end
      end
    end
  end
end
