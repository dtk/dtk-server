require 'ruote'
module DTK 
  module WorkflowAdapter
    class Ruote < DTK::Workflow
      r8_nested_require('ruote','participant')
      r8_nested_require('ruote','generate_process_defs')
      class Worker < ::Ruote::Worker
        def run_in_thread
          Thread.abort_on_exception = true
          @running = true

          user_object  = ::DTK::CurrentSession.new.user_object()
          @run_thread = CreateThread.defer_with_session(user_object) { run }
        end
      end

      # TODO: stubbed storage engine using hash store; look at alternatives like redis and
      # running with remote worker
      include RuoteParticipant
      include RuoteGenerateProcessDefs
      Engine = ::Ruote::Engine.new(Worker.new(::Ruote::HashStorage.new))
      # register all the classes
      ParticipantList = Array.new
      ObjectSpace.each_object(Module) do |m|
        next unless m.ancestors.include? Top and  m != Top
        participant = Aux.underscore(Aux.demodulize(m.to_s)).to_sym
        ParticipantList << participant
        Engine.register_participant participant, m
      end

      def cancel()
        Engine.cancel_process(@wfid)
      end

      def kill()
        Engine.kill_process(@wfid)
      end
      
      TopTaskDefaultTimeOut = 60 * 20 # in seconds

      def execute(top_task_id)
        begin
          @wfid = Engine.launch(process_def())

          # TODO: remove need to have to do Engine.wait_for and have last task trigger cleanup (which just 'wastes a  thread'
          Engine.wait_for(@wfid, :timeout => TopTaskDefaultTimeOut)
          
          # detect if wait for finished due to normal execution or errors 
          errors = Engine.errors(@wfid)
          if errors.nil? or errors.empty?
            pp :normal_completion
          else
            Log.error "-------- intercepted errors ------"
            errors.each  do |e|
              Log.error_pp e.message
              Log.error_pp e.trace.split("\n")
            end
            Log.error "-------- end: intercepted errors ------"

            # different ways to continue
            # one way is "fix error " ; engine.replay_at_error(err); engine.wait_for(@wfid)
            # this cancels everything
            # Engine.cancel_process(@wfid)
          end
         rescue Exception => e
          pp "error trap in ruote#execute"
          pp [e,e.backtrace[0..50]]
          # TODO: if do following Engine.cancel_process(@wfid), need to update task; somhow need to detrmine what task triggered this
         ensure
          TaskInfo.clean(top_task_id)
        end
        nil
      end

     private 
      def initialize(top_task)
        super
        @process_def = nil
      end
      def process_def()
        @process_def ||= compute_process_def(@top_task,@guards[:external])
        @process_def #TODO: just for testing so can checkpoint and see what it looks like
      end

      # This works under the assumption that task_ids are never reused
      class TaskInfo 
        
        Store = Hash.new
        Lock = Mutex.new
        
        def self.initialize_task_info()
          # deprecate
        end
        
        def self.set(top_task_id, task_id,task_info,task_type=nil)
          key = task_key(task_id,task_type, top_task_id)
          Lock.synchronize{Store[key] = task_info}
        end
        
        def self.get(task_id,task_type=nil,top_task_id=nil)
          key = task_key(task_id,task_type, top_task_id)
          ret = nil
          Lock.synchronize{ret = Store[key]}
          return ret
        end
        
        def self.delete(task_id,task_type=nil,top_task_id=nil)
          key = task_key(task_id,task_type)
          Lock.synchronize{Store.delete(key)}
        end

        def self.clean(top_task_id)
          Lock.synchronize{ Store.delete_if { |key, value| key.match(/#{top_task_id}.*/) } }
          pp [:write_cleanup,Store.keys]
          # TODO: this needs to clean all keys associated with the task; some handle must be passed in
          # TODO: if run through all the tasks this does not need to be called; so call to cleanup aborted tasks
        end

        def self.get_top_task_id(task_id)
          top_key = task_key(task_id)
          return top_key.split('-')[0] 
        end
       
       private
       # Amar: altered key format to enable top task cleanup by adding top_task_id on front
        def self.task_key(task_id,task_type=nil,top_task_id=nil)
          ret_key = task_id.to_s
          ret_key = "#{top_task_id.to_s}-#{ret_key}" if top_task_id
          ret_key = "#{ret_key}-#{task_type}" if task_type
          return ret_key if top_task_id

          Store.keys.each do |key|
            if key.match(/.*#{ret_key}/)
              ret_key = key 
              break
            end
          end
          return ret_key
        end
      end
    end
  end
end

# TODO: see if can do this by subclassing DispatchPool rather than monkey patch
###Monkey patches
# Amar: Additional monkey patching to support instant cancel of concurrent running subtasks on cancel task request
module Ruote
  class DispatchPool

    def retrive_user_info(msg)
      # content generated here can be found in generate_process_defs#participant
      user = ::DTK::User.from_json(msg['workitem']['fields']['params']['user_info']['user'])
      return user
    end
    def do_threaded_dispatch(participant, msg)
      
      msg = Rufus::Json.dup(msg)

      #
      # the thread gets its own copy of the message
      # (especially important if the main thread does something with
      # the message 'during' the dispatch)

      # Maybe at some point a limit on the number of dispatch threads
      # would be OK.
      # Or maybe it's the job of an extension / subclass

      DTK::CreateThread.defer_with_session(retrive_user_info(msg)) do
        begin
          do_dispatch(participant, msg)
        rescue => exception
          @context.error_handler.msg_handle(msg, exception)
        end
      end
    end
  end
end
