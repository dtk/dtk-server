module XYZ
  module WorkflowAdapter
    class RuoteReceiver < ::Ruote::Receiver
      def initialize(engine,listener)
        super(engine)
        @stop = nil
        @listener = listener
        @thread = Thread.new { listen }
        @thread.join
      end

      def stop()
        @stop = true
      end
      private
        def listen
          while not @stop
            @listener.process_event()
          end
        end
      end
    end
  end
end
