module XYZ
  module CommandAndControlAdapter
    class ProtocolMultiplexer
      def initialize(protocol_handler)
        #TODO: might put operations on @protocol_handler in mutex
        @protocol_handler = protocol_handler
        @callbacks_list = Hash.new
        @count_info = Hash.new
        @lock = Mutex.new
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
      DefaultTimeout = 180
      ExpectedCountDefault = 1
     public

      def process_response(msg,request_id)
        begin
          callbacks = get_and_remove_reqid_callbacks?(request_id)
          if callbacks
            callbacks.process_msg(msg,request_id)
          else
            pp "max count or timeout reached: dropping msg"
            pp msg
          end
         rescue Exception => e
          #TODO: more advanced would set failyue state on (sub)task
          Log.error("error in proceess_response: #{e.inspect}")
        end
      end

     private
      def process_request_timeout(request_id)
        callbacks = get_and_remove_reqid_callbacks(request_id)
        if callbacks
          callbacks.process_timeout(request_id) 
        end
      end

      def add_reqid_callbacks(request_id,callbacks,timeout,expected_count)
        @lock.synchronize do 
          timer = R8EM.add_timer(timeout){process_request_timeout(request_id)}
          @callbacks_list[request_id] = callbacks.merge(:timer => timer) 
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
            #TODO: protection from obscure error
            if @count_info[request_id]
              count = @count_info[request_id] -= 1
            else
              Log.error("@count_info[request_id] is null")
            end
          end
          if count == 0
            ret = @callbacks_list.delete(request_id)
            ret.cancel_timer()
          elsif count > 0
            ret = @callbacks_list[request_id]
          end
        end
        ret
      end

      class Callbacks < HashObject
        def self.create(callbacks_info)
          self.new(callbacks_info)
        end

        def process_msg(msg,request_id)
          callback = self[:on_msg_received]
          if callback
            callback.call(msg) 
          else
            Log.error("could not find process msg callback for request_id #{request_id.to_s}")
          end
        end

        def process_timeout(request_id)
          callback = self[:on_timeout]
          callback.call() if callback
        end

        def cancel_timer()
          timer = self[:timer]
          R8EM.cancel_timer(timer) if timer
        end
      end
    end
  end
end

