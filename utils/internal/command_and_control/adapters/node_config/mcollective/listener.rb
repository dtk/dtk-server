module XYZ
  module CommandAndControlAdapter
    class McollectiveListener
      def initialize(client)
        @client = client
        @request_info_store = Hash.new
        @lock = Mutex.new
      end
      def process_event()
        #pattern adapted from mcollective receive
        begin 
          msg = @client.receive
          match = update_if_match?(msg[:requestid])
          raise MsgDoesNotMatchARequestID unless match
         rescue MsgDoesNotMatchARequestID 
          retry
        end
        [msg,msg[:requestid]]
      end

      def add_request_id(request_id,opts={})
        req_opts = {:expected_count => opts[:expected_count], :timeout => opts[:timeout]||DefaultTimeout}
        request_info_set(request_id,req_opts)
      end

     private
      def request_info_set(request_id,val)
        @lock.synchronize{@request_info_store[request_id]=val}
        val
      end
      def update_if_match(request_id)
        #TODO: put in logic to deal with timouets 
        ret = nil 
        @lock.synchronize do 
          if request_info = @request_info_store[request_id]
            ret = true
            if request_info[:expected_count]
              request_info[:expected_count] -= 1
              @request_info_store.delete(request_id) if request_info[:expected_count] < 1
            end
          end
        end
        ret
      end

      DefaultTimeout = 120
      class MsgDoesNotMatchARequestID < RuntimeError; end
    end
  end
end



