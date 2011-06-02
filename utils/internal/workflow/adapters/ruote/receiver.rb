module XYZ
  module WorkflowAdapter
    class RuoteReceiver < ::Ruote::Receiver
      include RuoteCommon   
      def initialize(engine,listener)
        super(engine)
        #TODO: might put operations on @listener in mutex
        @listener = listener
        @callbacks_list = Hash.new
        @lock = Mutex.new
        common_init()
      end

      def process_request(trigger,context)
        request_id = trigger[:generate_request_id].call
        listener_opts = context.reject{|k,v| not [:agent,:expected_count].include?(k)}
        @listener.add_request_id(request_id,listener_opts)
        callbacks = Callbacks.create(context[:callbacks])
        timeout = context[:timeout]||DefaultTimeout
timeout = 5
        add_reqid_callbacks(request_id,callbacks,timeout)
        start?()
        trigger[:send_message].call(request_id)
      end
     private
      DefaultTimeout = 60

      def add_reqid_callbacks(request_id,callback_x,timeout=nil)
        callback = timeout ? 
          callback_x.merge(:timer => R8EM.add_timer(timeout){process_request_timeout(request_id)}) :
          callback_x
        @lock.synchronize{@callbacks_list[request_id] = callback}
      end

      def get_and_remove_reqid_callbacks(request_id)
        ret = nil
        @lock.synchronize{ret = @callbacks_list.delete(request_id)}
        ret
      end

      def loop
        while not is_stopped?()
          wait_and_process_message()
        end
      end

      def wait_and_process_message()
        msg,request_id = @listener.process_event()
        callbacks = get_and_remove_reqid_callbacks(request_id)
        callbacks.process_msg(msg,request_id)
      end

      def process_request_timeout(request_id)
        pp [:timeout, request_id]
        @listener.remove_request_id(request_id)
        callbacks = get_and_remove_reqid_callbacks(request_id)
        callbacks.process_timeout(request_id)
      end

      class Callbacks < HashObject
        def self.create(callbacks_info)
          self.new(callbacks_info)
        end

        def process_msg(msg,request_id)
          cancel_timer(request_id)
          callback = self[:on_msg_received]
          if callback
            callback.call(msg) 
          else
            Log.error("could not find process msg callback for request_id #{request_id.to_s}")
          end
        end
        def process_timeout(request_id)
          callback = self[:on_timeout]
          if callback
            callback.call()
          else
            Log.error("could not find timeout callback for request_id #{request_id.to_s}")
          end
        end
       private
        def cancel_timer(request_id)
          timer = self[:timer]
          R8EM.cancel_timer(timer) if timer
        end
      end
    end
  end
end

