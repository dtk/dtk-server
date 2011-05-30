module XYZ
  module CommandAndControl
    class McollectiveListener
      def initialize(client)
        @client = client
        @request_ids = Hash.new
        @lock = Mutex.new
      end
      def process_event()
        #pattern adapted from mcollective receive
        begin 
          msg = @client.receive
          match = nil
          @lock.synchronize do 
            match = @request_ids.has_key?(msg[:requestid])
            #TODO: put in logic to keep track of how many responses decrement expected count and if 0, delete
          end
          raise MsgDoesNotMatchARequestID unless match
         rescue MsgDoesNotMatchARequestID 
          retry
        end
        [msg,msg[:requestid]]
      end

      #TODO: for testing non private
      def add_request_id(request_id)
        #TODO: deal with expected count; nil is stub
        @lock.synchronize{@request_ids[request_id] = {:expected_count => nil}}
      end

     private
      class MsgDoesNotMatchARequestID < RuntimeError; end
    end
  end
end

#monkey patch
class MCollective::Client
  def receive(requestid = nil)
    msg = nil
    begin
      msg = @connection.receive
      msg = @security.decodemsg(msg)
      msg[:senderid] = Digest::MD5.hexdigest(msg[:senderid]) if ENV.include?("MCOLLECTIVE_ANON")
      #line patched added clause: requestid and
      raise(MsgDoesNotMatchRequestID, "Message reqid #{requestid} does not match our reqid #{msg[:requestid]}") if requestid and msg[:requestid] != requestid
    rescue SecurityValidationFailed => e
      @log.warn("Ignoring a message that did not pass security validations")
      retry
    rescue MsgDoesNotMatchRequestID => e
      @log.debug("Ignoring a message for some other client")
      retry
    end
    msg
  end
end

