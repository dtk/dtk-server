#mixins to deal with polling adn listening loops
module XYZ
  module WorkflowAdapter
    module RuoteCommon
      def start
        @is_stopped = false
        return if @thread
        @thread = CreateThread.defer do
          loop
        end
      end
      def stop()
        @is_stopped = true
        return unless @thread
        @thread.join
      end
     private
      def common_init()
        @is_stopped = true #initialized as stopped
        @thread = nil
      end
    end
  end
end
