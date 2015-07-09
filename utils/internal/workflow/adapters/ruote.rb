require 'ruote'
module DTK
  module WorkflowAdapter
    class Ruote < DTK::Workflow
      r8_nested_require('ruote', 'task_info')
      r8_nested_require('ruote', 'participant')
      r8_nested_require('ruote', 'generate_process_defs')
      class Worker < ::Ruote::Worker
        def run_in_thread
          Thread.abort_on_exception = true
          @running = true

          user_object  = ::DTK::CurrentSession.new.user_object()
          @run_thread = CreateThread.defer_with_session(user_object, Ramaze::Current.session) { run }
        end
      end

      # TODO: stubbed storage engine using hash store; look at alternatives like redis and
      # running with remote worker
      include RuoteParticipant
      include RuoteGenerateProcessDefs
      Engine = ::Ruote::Engine.new(Worker.new(::Ruote::HashStorage.new))
      # register all the classes
      ParticipantList = []
      ObjectSpace.each_object(Module) do |m|
        next unless m.ancestors.include?(Top) && m != Top
        participant = Aux.underscore(Aux.demodulize(m.to_s)).to_sym
        ParticipantList << participant
        Engine.register_participant participant, m
      end

      def cancel
        Engine.cancel_process(@wfid)
      end

      def kill
        Engine.kill_process(@wfid)
      end

      TopTaskDefaultTimeOut = 60 * 20 # in seconds

      def execute(top_task_id)
        begin
          @wfid = Engine.launch(process_def())

          # TODO: remove need to have to do Engine.wait_for and have last task trigger cleanup (which just 'wastes a  thread'
          Engine.wait_for(@wfid, timeout: TopTaskDefaultTimeOut)

          # detect if wait for finished due to normal execution or errors
          errors = Engine.errors(@wfid)
          if errors.nil? || errors.empty?
            Log.info_pp :normal_completion
          else
            Log.error '-------- intercepted errors ------'
            errors.each  do |e|
              Log.error_pp e.message
              Log.error_pp e.trace.split("\n")
            end
            Log.error '-------- end: intercepted errors ------'

            # different ways to continue
            # one way is "fix error " ; engine.replay_at_error(err); engine.wait_for(@wfid)
            # this cancels everything
            # Engine.cancel_process(@wfid)
          end
         rescue Exception => e
          Log.error_pp 'error trap in ruote#execute'
          Log.error_pp [e, e.backtrace[0..50]]
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

      def process_def
        @process_def ||= compute_process_def(@top_task, @guards[:external])
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
      ::DTK::User.from_json(msg['workitem']['fields']['params']['user_info']['user'])
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

      DTK::CreateThread.defer_with_session(retrive_user_info(msg), Ramaze::Current.session) do
        begin
          do_dispatch(participant, msg)
        rescue => exception
          @context.error_handler.msg_handle(msg, exception)
        end
      end
    end
  end
end
