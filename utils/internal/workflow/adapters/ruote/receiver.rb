module XYZ
  module WorkflowAdapter
    class RuoteReceiver < ::Ruote::Receiver
      def initialize(engine,listener,poller=nil)
        super(engine)
        @stop = nil
        @listener = listener
        @poller = poller
        @thread = Thread.new { listen }
        @thread.join
      end

      def stop()
        @stop = true
      end
      private
        def listen
          while not @stop
            msg = @listener.process_event()
            @poller.remove_item(msg) if @poller
            reply_to_engine(workitem_from_msg(msg)
          end
        end
        def workitem_from_msg(msg)
          #TODO: stub
          msg
        end
      end
    end
  end
end
