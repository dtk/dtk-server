module XYZ
  module WorkflowAdapter
    #generates polling requests that are listened to in reciever
    class RuotePoller
      def initialize(connection,receiver)
        @timers = Hash.new
        @connection = connection
        @receiver = receiver
        @cycle_time = 5
      end
      
      def add_item(poll_item,context,opts={})
        timer = R8EM.add_periodic_timer(@cycle_time) do
          request_id = poll_item.generate_request_id()
          rec_opts = {:from_poller => {:poller => self, :key => timer}}
          @receiver.add_request(request_id,context,rec_opts)
          poll_item.fire(request_id,@connection)
        end
        @timers[timer] = true
      end

      def remove_item(timer)
        timer.cancel()
        @timers.delete(timer)
      end
    end
  end
end
