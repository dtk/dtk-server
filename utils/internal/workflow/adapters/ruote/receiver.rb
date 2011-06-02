module XYZ
  module WorkflowAdapter
    class RuoteReceiver < ::Ruote::Receiver
      include RuoteCommon   
      def initialize(engine,listener)
        super(engine)
        #TODO: might put operations on @listener in mutex
        @listener = listener
        @callbacks = Hash.new
        @lock = Mutex.new
        common_init()
      end

      def add_request(request_id,callback_info)
        listener_opts = callback_info.reject{|k,v| not [:agent,:expected_count].include?(k)}
        @listener.add_request_id(request_id,listener_opts)
        callback = Callback.create(callback_info)
        if callback
          timeout = callback_info[:timeout]||DefaultTimeout
          add_callback(request_id,callback,timeout)
          start?()
        end
      end
     private
      DefaultTimeout = 60

      def add_callback(request_id,callback_x,timeout=nil)
        callback = timeout ? 
          callback_x.merge(:timer => R8EM.add_timer(timeout){process_request_timeout(request_id)}) :
          callback_x
        @lock.synchronize{@callbacks[request_id] = callback}
      end

      def get_and_remove_callback(request_id)
        ret = nil
        @lock.synchronize{ret = @callbacks.delete(request_id)}
        ret
      end

      def loop
        while not is_stopped?()
          wait_and_process_message()
        end
      end

      def wait_and_process_message()
        msg,request_id = @listener.process_event()
        callback = get_and_remove_callback(request_id)
        callback.process_msg(msg,request_id,self)
      end

      def process_request_timeout(request_id)
        pp [:timeout, request_id]
        @listener.remove_request_id(request_id)
        callback = get_and_remove_callback(request_id)
        callback.process_timeout(request_id,self)
      end

      class Callback < HashObject
        def self.create(callback_info)
          case callback_info[:type]
          when :workitem then CallbackWorkitem.new(callback_info)
          when :poller then CallbackPoller.new(callback_info)
          else 
            Log.error("unexpected callback type")
            nil
          end
        end

        def cancel_timer(request_id,opts={})
          timer = self[:timer]
          unless opts[:is_expired]
            R8EM.cancel_timer(timer) if timer
          end
        end
      end

      class CallbackWorkitem < Callback
        def process_msg(msg,request_id,receiver)
          cancel_timer(request_id)
          workitem = self[:workitem]
          if workitem
            workitem.fields["result"] = msg[:body].merge("task_id" => workitem.params["task_id"])
            receiver.reply_to_engine(workitem)
          else
            Log.error("could not find a workitem for request_id #{request_id.to_s}")
          end
        end
        def process_timeout(request_id,receiver)
          workitem = self[:workitem]
          if workitem
            workitem.fields["result"] = {"status" => "timeout", "task_id" => workitem.params["task_id"]}
            receiver.reply_to_engine(workitem)
          else
            Log.error("could not find a workitem for request_id #{request_id.to_s}")
          end
        end
      end
      class CallbackPoller < Callback
        #TODO: write routine
        #action for process timeout poller_info[:poller].remove_item(poller_info[:key])
      end
    end
  end
end

