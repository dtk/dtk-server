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
      def add_request(request_id,context,opts={})
        @workitem_store[request_id] = context.workitem
        @listener.add_request_id(request_id,context.opts.merge(opts))
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
          workitem.fields["result"] = msg
          reply_to_engine(workitem)
        else
          Log.error("could not find a workitem for request_id #{request_id.to_s}")
        end
      end
    end
    class RuoteReceiverContext < ReceiverContext
      attr_reader :workitem, :opts
      def initialize(workitem,opts={})
        @workitem = workitem
        @opts = opts
      end
    end
  end
end
