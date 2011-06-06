module XYZ
  #TODO: may make this a singleton
  #TODO: look at making this close to EM deferanle or leverage it so can cancel requests; ware callbacks look very equivalent
  #change stomp_em to have handle on  MCollectiveMultiplexer rather than handler
  module CommandAndControlAdapter
    class MCollectiveMultiplexer
      def initialize(protocol_handler)
        #TODO: might put operations on @protocol_handler in mutex
        @protocol_handler = protocol_handler
        @callbacks_list = Hash.new
        @lock = Mutex.new
        #TODO: think keep track of expected count here and coordinate with timeout
      end

      #TODO: can simplify to have request params abnd callback; may model on syntax of EM:defer future signature
      def process_request(trigger,context)
        request_id = trigger[:generate_request_id].call
        #TODO: handle context[:expected] count here buffer up and append responses until count is reached
        callbacks = Callbacks.create(context[:callbacks])
        timeout = context[:timeout]||DefaultTimeout
        add_reqid_callbacks(request_id,callbacks,timeout)
        trigger[:send_message].call(request_id)
      end
     private
      DefaultTimeout = 15 #90

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

      def process_message(msg,request_id)
        callbacks = get_and_remove_reqid_callbacks(request_id)
        callbacks.process_msg(msg,request_id)
      end

      def process_request_timeout(request_id)
        pp [:timeout, request_id]
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

