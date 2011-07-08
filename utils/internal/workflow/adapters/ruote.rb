#TODO: need to see whether we need both @task and task argument
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

      def execute(top_task_idh=nil)
        @task.update(:status => "executing") 
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
      
      def initiate_executable_action(action,task,top_task_idh,receiver_context)
        opts = {
          :initiate_only => true,
          :receiver_context => receiver_context
        }
        CommandAndControl.execute_task_action(action,task,top_task_idh,opts)
      end

      def poll_to_detect_node_ready(node,receiver_context,opts={})
        poll_opts = opts.merge({
          :receiver_context => receiver_context})
        CommandAndControl.poll_to_detect_node_ready(node,poll_opts)
      end

      attr_reader :listener
     private 
      def initialize(task,guards)
        super(task,guards)
        @process_def = nil
      end
      def process_def()
        @process_def ||= compute_process_def(task,guards)
        @process_def #TODO: just for testing so can checkpoint and see what it looks like
      end

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
    end
  end
end
