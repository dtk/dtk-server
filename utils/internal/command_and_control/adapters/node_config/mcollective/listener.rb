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

      #TODO: for testing non private
      def add_request_id(request_id)
        @request_ids << request_id
      end

     private
      class MsgDoesNotMatchARequestID < RuntimeError; end
    end
  end
end


