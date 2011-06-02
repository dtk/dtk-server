#TODO: need to pass back return for all actions; now if do create and update; only update put in
module XYZ
  module WorkflowAdapter
    #abstarct class
    class ReceiverContext 
    end
  end

  class Workflow
    def defer_execution(top_level_task)
      CreateThread.defer do
      #  pp [:new_thread_from_defer, Thread.current, Thread.list]
        raise Error.new("not implemented: putting block in reactor loop when not using eventmachine web server") unless R8EM.reactor_running?
        begin
          top_task_id = top_level_task.id_handle.get_id()
          pp "starting top_task_id = #{top_task_id.to_s}"
          execute()
         rescue Exception => e
          Log.error("error in commit background job: #{e.inspect}")
          pp e.backtrace[0..10]
        end
        pp "end of commit_changes defer"
        pp "----------------"
      end
    end

    #virtual fns that get ovewritten
    def execute(top_task_idh=nil)
    end

    ######

    def self.create(task)
      Adapter.new(task)
    end


    def update_task(hash)
      @task.update(hash)
    end

    attr_reader :task

    def process_executable_action(executable_action,top_task_idh)
      self.class.process_executable_action(@task,executable_action,top_task_idh)
    end

    def initiate_executable_action(executable_action,top_task_idh,receiver_context)
      opts = {:initiate_only => true, :connection => @connection, :receiver => @receiver,:receiver_context => receiver_context}
      CommandAndControl.execute_task_action(executable_action,@task,top_task_idh,opts)
    end

    def poll_to_detect_node_ready(node,receiver_context)
      opts = {:initiate_only => true, :connection => @connection, :receiver => @receiver,:receiver_context => receiver_context}
      CommandAndControl.poll_to_detect_node_ready(node,opts)
    end

   private
    klass = self
    begin
      type = R8::Config[:workflow][:type]
      require File.expand_path("#{UTILS_DIR}/internal/workflow/adapters/#{type}", File.dirname(__FILE__))
      klass = XYZ::WorkflowAdapter.const_get type.capitalize
     rescue LoadError => e
      pp [e,e.backtrace[0..5]]
      raise.Error.new("cannot find workflow adapter")
    end
    Adapter = klass

    def initialize(task)
      @task = task
      @connection = nil
    end

    def self.process_executable_action(task,executable_action,top_task_idh)
      debug_print_task_info = "task_id=#{task.id.to_s}; top_task_id=#{top_task_idh.get_id()}"
      begin 
        result_hash = CommandAndControl.execute_task_action(executable_action,task,top_task_idh)
        update_hash = {
          :status => "succeeded",
          :result => TaskAction::Result::Succeeded.new(result_hash)
        }
        task.update(update_hash)
        executable_action.update_state_change_status(task.model_handle,:completed)  #this send pending changes' states
        debug_pp [:task_succeeded,debug_print_task_info,result_hash]
        :succeeded              
      rescue CommandAndControl::Error => e
        update_hash = {
          :status => "failed",
          :result => TaskAction::Result::Failed.new(e)
        }
        task.update(update_hash)
        debug_pp [:task_failed,debug_print_task_info,e]
        :failed
      rescue Exception => e
        update_hash = {
          :status => "failed",
          :result => TaskAction::Result::Failed.new(CommandAndControl::Error.new)
        }
        task.update(update_hash)
        debug_pp [:task_failed_internal_error,debug_print_task_info,e,e.backtrace]
        :failed
      end
    end

    def self.debug_pp(x)
      @@debug_lock.synchronize{pp x}
    end
    @@debug_lock = Mutex.new
  end
end

