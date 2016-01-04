module XYZ
  module CommandAndControlAdapter
    class ProtocolMultiplexer
      def initialize(protocol_handler = nil)
        # TODO: might put operations on @protocol_handler in mutex
        @protocol_handler = protocol_handler
        @callbacks_list = {}
        @count_info = {}
        @lock = Mutex.new
      end

      def set(protocol_handler)
        @protocol_handler = protocol_handler
        self
      end

      # TODO: may model more closely to syntax of EM:defer future signature
      def process_request(trigger, context)
        request_id = trigger[:generate_request_id].call(@protocol_handler)
        callbacks = Callbacks.create(context[:callbacks])
        timeout = context[:timeout] || DefaultTimeout
        expected_count = context[:expected_count] || ExpectedCountDefault
        add_reqid_callbacks(request_id, callbacks, timeout, expected_count)
        trigger[:send_message].call(@protocol_handler, request_id)
      end

      DefaultTimeout = 30 * 60
      ExpectedCountDefault = 1

      def process_response(msg, request_id)
        callbacks = nil
        begin
          callbacks = get_and_remove_reqid_callbacks?(request_id)
          if (is_cancel_response(msg))
            callbacks.process_cancel()
          elsif callbacks
            callbacks.process_msg(msg, request_id)
          else
            Log.error 'max count or timeout reached: dropping msg'
          end
         rescue Exception => e
          # TODO: this is last resort trap; if this is reached the user will have to manually cancel the task
          Callbacks.process_error(callbacks, e)
        end
      end

      private

      def is_cancel_response(_msg)
        false
        # return msg[:body] && msg[:body][:data] && msg[:body][:data][:status] && msg[:body][:data][:status] == :canceled
      end

      def process_request_timeout(request_id)
        # DEBUG SNIPPET >>> REMOVE <<<
        require 'ap'
        ap "ENTERED !!! Timeout"
        callbacks = get_and_remove_reqid_callbacks(request_id)
        # DEBUG SNIPPET >>> REMOVE <<<
        require 'ap'
        ap "Processing timeout"
        ap "Callbacks are here"
        if callbacks
          callbacks.process_timeout(request_id)
        end
      end

      def add_reqid_callbacks(request_id, callbacks, timeout, expected_count)
        @lock.synchronize do
          # DEBUG SNIPPET >>> REMOVE <<<
          require 'ap'
          ap "TIMEOUT ADDED WITH R8EM #{timeout}"
          timer = R8EM.add_timer(timeout) { process_request_timeout(request_id) }
          @callbacks_list[request_id] = callbacks.merge(timer: timer)
          # DEBUG SNIPPET >>> REMOVE <<<
          require 'ap'
          ap "ADDED REQUEST ID: #{request_id}"
          @count_info[request_id] = expected_count
        end
      end

      def get_and_remove_reqid_callbacks(request_id)
        get_and_remove_reqid_callbacks?(request_id, force_delete: true)
      end
      #'?' because conditionally removes callbacks depending on count
      def get_and_remove_reqid_callbacks?(request_id, opts = {})
        ret = nil
        # DEBUG SNIPPET >>> REMOVE <<<
        require 'ap'
        ap "REMOVING CALLBACKS"
        @lock.synchronize do
          if opts[:force_delete]
            count = @count_info[request_id] = 0
          else
            # TODO: protection from obscure error
            if @count_info[request_id]
              count = @count_info[request_id] -= 1
            else
              Log.error('@count_info[request_id] is null')
              return nil
            end
          end
          if count == 0
            ret = @callbacks_list.delete(request_id)
                      # DEBUG SNIPPET >>> REMOVE <<<
          require 'ap'
          ap "DELETE REQUEST ID: #{request_id}"

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

        def self.process_error(callbacks, error_obj)
          unless callbacks && callbacks.process_error(error_obj)
            Log.error("Error in process_response: #{error_obj.inspect}")
            Log.error_pp(error_obj.backtrace)
          end
        end

        def process_msg(msg, request_id)
          callback = self[:on_msg_received]
          if callback
            callback.call(msg)
          else
            Log.error("Could not find process msg callback for request_id #{request_id}")
          end
        end

        def process_timeout(_request_id)
          # DEBUG SNIPPET >>> REMOVE <<<
          require 'ap'
          ap "PROCESS TIEMOUT METHOD CALL IT NOW #{_request_id}"
          callback = self[:on_timeout]
          callback.call() if callback
        end

        def process_cancel
          callback = self[:on_cancel]
          callback.call() if callback
        end

        def cancel_timer
          timer = self[:timer]
          R8EM.cancel_timer(timer) if timer
        end

        def process_error(error_object)
          callback = self[:on_error]
          if callback
            callback.call(error_object)
            true
          end
        end
      end
    end
  end
end
