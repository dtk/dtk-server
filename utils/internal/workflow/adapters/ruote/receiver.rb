module XYZ
  module WorkflowAdapter
    class RuoteReceiver < ::Ruote::Receiver
      include RuoteCommon   
      def initialize(engine,listener)
        super(engine)
        @listener = listener
        @request_ids = Array.new
        common_init()
      end
     private
      def loop
        while not @is_stopped #TODO: dont think necsssary to put this test in mutex
          msg,request_id = @listener.process_event()
          reply_to_engine(workitem_from_msg(msg,request_id))
        end
      end
      def workitem_from_msg(msg,request_id)
        #TODO: stub
        msg
      end
    end
  end
end
