require File.expand_path('amqp_clients_wrapper', File.dirname(__FILE__))
module XYZ
  class WorkerTask
    attr_reader :input_msg,:status,:return_code,:errors,:log_entries
    attr_accessor :parent_task,:results

    private

    def initialize(input_msg,opts)
      @input_msg = input_msg
      @caller_channel = nil
      @msg_bus_client = nil

      @status = :initiated
      @parent_task = nil
      @return_code = nil
      @results = opts[:results] #results can be set if caller fn did the computation
      @errors = []
      @log_entries = []

      # TBD: what about events and logged msgs
    end

    public

    def add_reply_to_info(caller_channel,msg_bus_client)
      @caller_channel = caller_channel
      @msg_bus_client = msg_bus_client
      extend InstanceMixinReplyToCaller
    end

    def add_log_entry(type,params={})
      @log_entries << WorkerTaskLogEntry.create(type,params)
    end

    def self.create(type,input_msg,opts={})
      case type
        when :basic
          WorkerTaskBasic.create(input_msg,opts)
        when :local
          WorkerTaskLocal.new(input_msg,opts)
        when :remote
          WorkerTaskRemote.new(input_msg,opts)
        when :task_set
          WorkerTaskSet.create(input_msg,opts)
        else
         raise Error.new("#{type} is not a legal worker task type")
      end
    end
    def process_task_finished
      @status = :complete #TBD: where to we distinguish whether error or not
      if @parent_task
        # if within parent task, signal this (sub) task finished
        # if last task finished and there is a caller channel tehn this
        # below wil reply to caller; so not needed explicitly here
        @parent_task.process_child_task_finished()
      else
        reply_to_caller() if @caller_channel
      end
    end

    def add_routing_info(_opts)
      # no op (unless overwritten)
    end

    def set_so_can_run_concurrently
      # no op (unless overwritten)
    end

    private

    def reply_to_caller
      # no op (unless overwritten)
    end
  end

  module InstanceMixinReplyToCaller
    private

    def reply_to_caller
      raise Error.new('cannot call reply_to_caller() if caller_channel not set') unless @caller_channel
      raise Error.new('cannot call reply_to_caller() if msg_bus_client not set') unless @msg_bus_client
      reply_queue = @msg_bus_client.publish_queue(@caller_channel,passive: true)
      input_msg_reply = ProcessorMsg.create({msg_type: :task})
      # TBD: stub; want to strip out a number of these fields
      # only send a subset of task info
      task = WorkerTaskWireSubset.new(self)
      reply_queue.publish(input_msg_reply.marshal_to_message_bus_msg(),
        {message_id: @caller_channel, task: task})
    end
  end

  class WorkerTaskSet < WorkerTask
    attr_reader :subtasks
    def self.create(input_msg,opts={})
      temporal_sequencing = opts[:temporal_sequencing] || :concurrent
      case temporal_sequencing
  when :concurrent
          WorkerTaskSetConcurrent.new(input_msg,opts)
  when :sequential
          WorkerTaskSetSequential.new(input_msg,opts)
 else
          raise Error.new("#{temporal_sequencing} is an illegal temporal sequencing type")
      end
    end

    private

    def initialize(input_msg,opts={})
      super(input_msg,opts)
      @subtasks = []
      @num_tasks_not_complete = 0
    end

    public

    def add_task(task)

      task.set_so_can_run_concurrently if self.is_a?(WorkerTaskSetConcurrent)
      @subtasks << task
      task.parent_task = self
      @num_tasks_not_complete = @num_tasks_not_complete + 1
    end

    def add_routing_info(opts)
      @subtasks.each{|t|t.add_routing_info(opts)}
    end

    def determine_local_and_remote_tasks!(worker)
      @subtasks.each{|t|t.determine_local_and_remote_tasks!(worker)}
    end
  end

  class WorkerTaskSetConcurrent < WorkerTaskSet
    def execute
      if @subtasks.size > 0
        # process_task_finished() triggered by last complete subtasks
        @subtasks.each(&:execute)
      else
        process_task_finished()
      end
    end

    def process_child_task_finished
      @num_tasks_not_complete = @num_tasks_not_complete - 1
      if @num_tasks_not_complete < 1
        #        Log.debug_pp [:finished,WorkerTaskWireSubset.new(self)]
        Log.debug_pp [:finished,WorkerTaskWireSubset.new(self).flatten()]
        process_task_finished()
      end
    end
  end

  class WorkerTaskSetSequential < WorkerTaskSet
    def execute
      if @subtasks.size > 0
        # start first sub task and this will set chain that callss subsequent ones
        @subtasks.first.execute()
      else
        process_task_finished()
      end
    end

    def process_child_task_finished
      @num_tasks_not_complete = @num_tasks_not_complete - 1
      if @num_tasks_not_complete < 1
        #        Log.debug_pp [:finished,WorkerTaskWireSubset.new(self)]
        Log.debug_pp [:finished,WorkerTaskWireSubset.new(self).flatten()]
        process_task_finished()
      else
        i = @subtasks.size - @num_tasks_not_complete
        @subtasks[i].execute()
      end
    end
  end

  class WorkerTaskBasic < WorkerTask
    attr_reader :task_type

    private

    def initialize(input_msg,opts={})
      super(input_msg,opts)
      @task_type = nil
    end

    public

    def self.create(input_msg,opts={})
      WorkerTaskBasic.new(input_msg,opts)
    end

    def determine_local_and_remote_tasks!(_worker)
      # no op if basic types extended already
      return nil unless self.class == WorkerTaskBasic
      # TBD: stub where can optimize by appropriately making thsi local call
      extend_as_remote()
    end

    private

    def extend_as_remote
      @task_type = :remote
      extend MixinWorkerTaskRemote if self.class == WorkerTaskBasic
      initialize_remote()
    end

    def extend_as_local
      @task_type = :local
      extend MixinWorkerTaskLocal if self.class == WorkerTaskBasic
      initialize_local()
    end
  end

  module MixinWorkerTaskRemote
    attr_reader :delegated_task
    def initialize_remote
      @queue_name = nil
      @exchange_name = nil

      # opts related to creating queue or exchange
      # legal values: [:type, :passive, :durable, :exclusive, :auto_delete, :nowait, :internal]
      @create_opts = {}

      # legal values: [:key, :reply_timeout]
      @publish_opts = {}

      # gets task status results back from delagated worker
      @delegated_task = nil
    end

    def add_routing_info(opts)
      @msg_bus_client = opts[:msg_bus_client]

      # TDB: stub to find queue or exchange to publish on
      if @input_msg.msg_type == :execute_on_node
        @queue_name = @input_msg.key()
        @create_opts[:passive] = true
      else
        @exchange_name = @input_msg.topic()
        @create_opts[:type] = :topic
        @publish_opts[:key] = @input_msg.key()
      end
    end

    def execute
      begin
        queue_or_exchange = ret_queue_or_exchange()
        @status = :started
        msg_bus_msg_out = @input_msg.marshal_to_message_bus_msg()
        Log.debug_pp [:sending_to,
                      @queue_name ? "queue #{@queue_name}" : "exchange #{@exchange_name}",
                      msg_bus_msg_out]
        queue_or_exchange.publish_with_callback(msg_bus_msg_out,@publish_opts) do |trans_info,msg_bus_msg_in|
          Log.debug_pp [:received_from, trans_info,msg_bus_msg_in]
          @delegated_task = trans_info[:task]
          process_task_finished()
        end
       rescue Error::AMQP::QueueDoesNotExist => e
        if @input_msg.is_a?(ProcessorMsg) and @input_msg.msg_type == :execute_on_node
          @errors << WorkerTaskErrorNodeNotConnected.new(e.queue_name.to_i())
        else
          @errors << WorkerTaskError.new(e)
        end
        process_task_finished()
       rescue Exception => e
        @errors << WorkerTaskError.new(e)
        #       Log.debug_pp [:error,e,e.backtrace]
        process_task_finished()
      end
    end

    private

    # can throw an error (e.g., if passive and queue does not exist)
    def ret_queue_or_exchange
      if @queue_name
  @msg_bus_client.publish_queue(@queue_name,@create_opts||{})
      else # #@exchange_name
  @msg_bus_client.exchange(@exchange_name,@create_opts||{})
      end
    end
  end

  class WorkerTaskRemote < WorkerTaskBasic
    include MixinWorkerTaskRemote
    def initialize(input_msg,opts={})
      super(input_msg,opts)
      extend_as_remote()
    end
  end

  module MixinWorkerTaskLocal
    def initialize_local
      @work = proc{}
      @run_in_new_thread_or_fork = nil
    end

    def add_work_info(opts)
      @work = proc do
        begin
          opts[:work].call()
         rescue  Exception => e
          Log.debug_pp [e,e.backtrace]
          # TBD: since this can be arbitrary error as stop gap measure converting to_s; ?: should I do same for errors with different tasks or only needed here because can get arbitrary for example chef errors
          @errors << WorkerTaskError.new(e.to_s)
          :failed
        end
      end
      @run_in_new_thread_or_fork = opts[:run_in_new_thread_or_fork]
    end

    def set_so_can_run_concurrently
      @run_in_new_thread_or_fork = true
    end

    def execute
      # modified from design pattern from right_link
      callback = proc do |results|
         @results = results
         @return_code = @errors.empty?() ? :succeeded : :failed
         process_task_finished()
      end
      if @run_in_new_thread_or_fork
        EM.defer(@work,callback)
      else
        # TBD: using next_tick is from rightlink design pattern; need to work through all shuffles to
        # see if this is what we want
        EM.next_tick {callback.call(@work.call())}
      end
    end
  end

  class WorkerTaskLocal < WorkerTaskBasic
    include MixinWorkerTaskLocal
    def initialize(input_msg,opts={})
      super(input_msg,opts)
      extend_as_local()
      add_work_info(opts)
    end
  end

  class WorkerTaskError
    def initialize(err_obj)
      @error = err_obj
    end
  end
  class WorkerTaskErrorNodeNotConnected < WorkerTaskError
    def initialize(node_guid)
      @node_guid = node_guid
    end
  end

  class WorkerTaskLogEntry < HashObject
    def self.create(type,params={})
      WorkerTaskLogEntry.new(type,params)
    end

    private

    def initialize(type,params={})
      super(params.merge(type: type))
    end
  end
end

# TBD: reconcile this, what is above in task in db model; this might be same as what is in db; or this may be object in
# TBD: may rename WorkTaskStatus, although may be better word because not exactly "snapshot"
module XYZ
  class WorkerTaskWireSubset < HashObject
    def initialize(tsk)
      super({})
      self[:input_msg] = tsk.input_msg
      self[:status] = tsk.status if tsk.status
      self[:return_code] = tsk.return_code if tsk.return_code
      self[:errors] = tsk.errors if tsk.errors and !tsk.errors.empty?()
      self[:log_entries] = tsk.log_entries if tsk.log_entries and !tsk.log_entries.empty?()

      if tsk.is_a?(WorkerTaskBasic) and tsk.task_type == :remote
        self[:delegated_task] = tsk.delegated_task
      elsif tsk.is_a?(WorkerTaskSet)
        self[:subtasks] = tsk.subtasks.map{|t|WorkerTaskWireSubset.new(t)}
      end

      # TBD: whether results should come back in task info or in other spot, such as
      # place where it could be called in a block after request
      self[:results] = tsk.results if tsk.results
    end

    # TBD: rather than having wire object with delegation links, may flatten while producing
    # TBD: may write so that if subtasks or delegated parts falttened already its a no op
    # flatten removes the links to delegated
    def flatten
      ret =
        if self[:delegated_task]
          self[:delegated_task].flatten()
        else
          {}
      end

      input_msg = nil
      if self[:input_msg].is_a?(ProcessorMsg)
        input_msg = {msg_type: self[:input_msg].msg_type}
        input_msg[:msg_content] =  self[:input_msg].msg_content unless self[:input_msg].msg_content.empty?
      else
         input_msg = self[:input_msg]
       end
      ret[:input_msg] ||= input_msg
      ret[:status] ||= self[:status] if self[:status]
      ret[:return_code] ||= self[:return_code] if self[:return_code]
      ret[:errors] ||= self[:errors] if self[:errors]
      ret[:log_entries] ||= self[:log_entries] if self[:log_entries]
      ret[:results] ||= self[:results] if self[:results]
      ret[:subtasks] ||= self[:subtasks].map(&:flatten) if self[:subtasks] and !self[:subtasks].empty?
      ret
    end
  end
end
