module XYZ
  module CommandAndControlAdapter
    class McollectiveListener
      def initialize(rpc_client)
        @rpc_client = rpc_client
        @request_info_store = Hash.new
        @lock = Mutex.new
      end
      def process_event()
        #pattern adapted from mcollective receive
        begin 
          msg = @rpc_client.client.receive
          match = update_if_match?(msg[:requestid])
          raise MsgDoesNotMatchARequestID unless match
         rescue MsgDoesNotMatchARequestID 
          retry
        end
        [msg,msg[:requestid]]
      end

      def add_request_id(request_id,opts)
        raise Error.new("not yet implementended expected_count > 1") if opts[:expected_count] > 1
        @rpc_client.client.r8_add_subscription?(opts[:agent])
        req_opts = {:expected_count => opts[:expected_count]}
        set_request_info(request_id,req_opts)
      end
      
      def remove_request_id(request_id)
        @lock.synchronize{@request_info_store.delete(request_id)}
      end

     private
      def set_request_info(request_id,val)
        @lock.synchronize{@request_info_store[request_id]=val}
        val
      end
      def update_if_match?(request_id)
        #TODO: put in logic to deal with timouets 
        ret = nil 
        @lock.synchronize do 
          pp [:receiving,request_id]
          if request_info = @request_info_store[request_id]
            pp [:accepting, request_id]
            ret = true
            if request_info[:expected_count]
              request_info[:expected_count] -= 1
              @request_info_store.delete(request_id) if request_info[:expected_count] < 1
            end
          end
        end
        ret
      end

      class MsgDoesNotMatchARequestID < RuntimeError; end
    end
  end
end



