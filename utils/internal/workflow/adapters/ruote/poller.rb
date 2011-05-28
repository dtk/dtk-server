module XYZ
  module WorkflowAdapter
    #generates polling requests that are listened to in reciever
    class RuotePoller
      def initialize(poller,receiver)
        @stop = nil
        @poller = poller
        @reciever = receiver
        @thread = Thread.new { poll }
        @thread.join
        @cycle_time = 5
      end

      def stop()
        @stop = true
      end

      def add_item(poll_item)
        @reciever.subscribe(poll_item)
        @poller.add_item(poll_item)
      end

      def remove_item(msg)
        @poller.remove_item(msg)
      end

      private
        def poll
          while not @stop
            sleep @cycle_time
            #TODO: may splay for multiple items
            @poller.send()
          end
        end
      end
    end
  end
end
