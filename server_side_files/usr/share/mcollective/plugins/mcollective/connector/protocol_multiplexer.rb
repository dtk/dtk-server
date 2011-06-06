module XYZ
  module CommandAndControlAdapter
    class ProtocolMultiplexer
      def initialize(protocol_handler)
        #TODO: might put operations on @protocol_handler in mutex
        @protocol_handler = protocol_handler
        @callbacks_list = Hash.new
        @count_info = Hash.new
        @lock = Mutex.new
        #TODO: keep track of expected count here and coordinate with timeout
      end

      #TODO: may model more closely to syntax of EM:defer future signature
      def process_request(trigger,context)
        request_id = trigger[:generate_request_id].call(@protocol_handler)
        callbacks = Callbacks.create(context[:callbacks])
        timeout = context[:timeout]||DefaultTimeout
        expected_count = context[:expected_count]||ExpectedCountDefault
        add_reqid_callbacks(request_id,callbacks,timeout,expected_count)
        trigger[:send_message].call(@protocol_handler,request_id)
      end
     private
      DefaultTimeout = 30 #90
      ExpectedCountDefault = 1
     public

      def process_response(msg,request_id)
        callbacks = get_and_remove_reqid_callbacks?(request_id)
        if callbacks
          callbacks.process_msg(msg,request_id)
        else
          pp "max count or timeout reached: dropping msg"
          pp msg
        end
      end

     private
      def process_request_timeout(request_id)
        pp [:timeout, request_id]
        callbacks = get_and_remove_reqid_callbacks(request_id)
        callbacks.process_timeout(request_id)
      end


      def add_reqid_callbacks(request_id,callbacks_x,timeout,expected_count)
        callbacks = callbacks_x.merge(:timer => R8EM.add_timer(timeout){process_request_timeout(request_id)}) 
        @lock.synchronize do 
          @callbacks_list[request_id] = callbacks 
          @count_info[request_id] = expected_count
        end
      end

      def get_and_remove_reqid_callbacks(request_id)
        get_and_remove_reqid_callbacks?(request_id,:force_delete => true)
      end
      #'?' because conditionally removes callbacks depending on count
      def get_and_remove_reqid_callbacks?(request_id,opts={})
        ret = nil
        @lock.synchronize do
          if opts[:force_delete]
            count = @count_info[request_id] = 0
          else
            count = @count_info[request_id] -= 1
          end
          if count == 0
            ret = @callbacks_list.delete(request_id)
          elsif count > 0
            ret = @callbacks_list[request_id]
          end
        end
        ret
      end

      #TODO: XYZ prefix temp until in rest of code
      class Callbacks < XYZ::HashObject
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
          EM.cancel_timer(timer) if timer
        end
      end
    end
  end
end

