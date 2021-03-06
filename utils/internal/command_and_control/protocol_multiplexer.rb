#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
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
        callbacks = get_and_remove_reqid_callbacks(request_id)
        if callbacks
          callbacks.process_timeout(request_id)
        end
      end

      def add_reqid_callbacks(request_id, callbacks, timeout, expected_count)
        @lock.synchronize do
          timer = R8EM.add_timer(timeout) { process_request_timeout(request_id) }
          @callbacks_list[request_id] = callbacks.merge(timer: timer)
          @count_info[request_id] = expected_count
        end
      end

      def get_and_remove_reqid_callbacks(request_id)
        get_and_remove_reqid_callbacks?(request_id, force_delete: true)
      end
      #'?' because conditionally removes callbacks depending on count
      def get_and_remove_reqid_callbacks?(request_id, opts = {})
        ret = nil

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