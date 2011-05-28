module XYZ
  module CommandAndControl
    class McollectiveListener
      def initialize(client)
        @client = client
        @request_ids = Array.new
      end
      def process_event()
        #pattern adapted from mcollective receive
        begin 
          msg = @client.receive
          raise MsgDoesNotMatchARequestID unless @request_ids.delete(msg[:requestid])
         rescue MsgDoesNotMatchARequestID 
          retry
        end
        msg
      end

     private
      class MsgDoesNotMatchARequestID < RuntimeError; end
    end
  end
end


