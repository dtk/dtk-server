module DTK; class Error
  class AMQP 
    class QueueDoesNotExist < self
      attr_reader :queue_name

      def initialize(queue_name)
        @queue_name = queue_name
      end

      def to_s()
        "queue #{queue_name} does not exist"
      end
    end
  end
end; end
