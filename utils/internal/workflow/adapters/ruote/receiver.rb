module XYZ
  module WorkflowAdapter
    class RuoteReceiver < ::Ruote::Receiver
      include RuoteCommon   
      def initialize(engine,listener)
        super(engine)
        #TODO: might put operations on @listener in mutex
        @listener = listener
        @request_ids = Array.new
        common_init()
        @workitem_store = Hash.new
      end
      def add_request(request)
        request_id = request.id
        @workitem_store[request_id] = request.workitem
        @listener.add_request_id(request_id,request.opts)
        start()
      end
     private
      def loop
        while not @is_stopped #TODO: dont think necsssary to put this test in mutex
          wait_and_process_message()
        end
      end
      def wait_and_process_message()
        msg,request_id = @listener.process_event()
        workitem = @workitem_store.delete(request_id)
        if workitem
          workitem.field["result"] = msg
          reply_to_engine(workitem)
        else
          Log.error("could not find a workitem for request_id #{request_id.to_s}")
        end
      end
    end
    class RuoteReceiverRequest
      attr_reader :id,:workitem, :opts
      def initialize(request_id,workitem,opts={})
        @id = request_id
        @workitem = workitem
        @opts = opts
      end
    end
  end
end
