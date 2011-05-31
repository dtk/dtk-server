#mixins to deal with polling adn listening loops
module XYZ
  module WorkflowAdapter
    module RuoteCommon
      #TODO: need to put in logic to kill the loop thread
      def start
        @lock_is_stopped.synchronize do
          if @is_stopped
            @is_stopped = false
            @thread ||= CreateThread.defer{loop}
          end
        end
      end
      #called inside loop
      def stop()
        pp ["receiver is being stopped"] unless @is_stopped
        @lock_is_stopped.synchronize{@is_stopped = true}
      end
      def is_stopped?()
        ret = nil
        @lock_is_stopped.synchronize{ret = @is_stopped}
        ret
      end
     private
      def common_init()
        @is_stopped = true #initialized as stopped
        @thread = nil
        @lock_is_stopped = Mutex.new
      end
    end
  end
end
