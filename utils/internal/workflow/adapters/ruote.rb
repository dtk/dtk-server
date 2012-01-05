require 'ruote'
require File.expand_path('ruote/participant', File.dirname(__FILE__))
require File.expand_path('ruote/generate_process_defs', File.dirname(__FILE__))

module XYZ 
  module WorkflowAdapter
    class Ruote < XYZ::Workflow
      #TODO: stubbed storage engine using hash store; look at alternatives like redis and
      #running with remote worker
      include RuoteParticipant
      include RuoteGenerateProcessDefs
      Engine = ::Ruote::Engine.new(::Ruote::Worker.new(::Ruote::HashStorage.new))
      #register all the classes
      ParticipantList = Array.new
      ObjectSpace.each_object(Module) do |m|
        next unless m.ancestors.include? Top and  m != Top
        participant = Aux.underscore(Aux.demodulize(m.to_s)).to_sym
        ParticipantList << participant
        Engine.register_participant participant, m
      end

      def execute()
        TaskInfo.initialize_task_info()
        begin
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
          TaskInfo.clean
        end
        nil
      end
      
      def initiate_executable_action(task,receiver_context)
        opts = {
          :initiate_only => true,
          :receiver_context => receiver_context
        }
        CommandAndControl.execute_task_action(task,top_task_idh,opts)
      end

      def poll_to_detect_node_ready(node,receiver_context,opts={})
        poll_opts = opts.merge({
          :receiver_context => receiver_context})
        CommandAndControl.poll_to_detect_node_ready(node,poll_opts)
      end

     private 
      def initialize(top_task,guards)
        super(top_task,guards)
        @process_def = nil
      end
      def process_def()
        @process_def ||= compute_process_def(@top_task,@guards[:external])
        @process_def #TODO: just for testing so can checkpoint and see what it looks like
      end

      #This works under the assumption that task_ids are never reused
      class TaskInfo 
        Store = Hash.new
        Lock = Mutex.new
        def self.initialize_task_info()
          #deprecate
        end
        def self.set(task_id,task_info,task_type=nil)
          key = task_key(task_id,task_type)
          Lock.synchronize{Store[key] = task_info}
        end
        def self.get_and_delete(task_id,task_type=nil)
          key = task_key(task_id,task_type)
          ret = nil
          Lock.synchronize{ret = Store.delete(key)}
          ret 
        end
        def self.clean()
          pp [:write_cleanup,Store.keys]
          #TODO: this needs to clean all keys associated with the task; some handle must be passed in
          #TODO: if run through all the tasks this does not need to be called; so call to cleanup aborted tasks
        end
       private
        def self.task_key(task_id,task_type)
          task_type ? "#{task_id.to_s}-#{task_type}" : task_id.to_s
        end
      end
=begin
      #TODO: this does not work for concurrent tasks because @count is not updated at right time
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
=end
    end
  end
end

###Monkey patches
module Ruote
  class DispatchPool
    def do_threaded_dispatch(participant, msg)

      msg = Rufus::Json.dup(msg)
        #
        # the thread gets its own copy of the message
        # (especially important if the main thread does something with
        # the message 'during' the dispatch)

      # Maybe at some point a limit on the number of dispatch threads
      # would be OK.
      # Or maybe it's the job of an extension / subclass

      Thread.new do
        begin

          do_dispatch(participant, msg)

        rescue => exception
          @context.error_handler.msg_handle(msg, exception)
        end
      end
    end
  end
end
require 'ruote/worker'
module Ruote
  class Worker
    def run_in_thread

      Thread.abort_on_exception = true
        # TODO : remove me at some point

      @running = true

      @run_thread = Thread.new { run }
    end
  end
end

