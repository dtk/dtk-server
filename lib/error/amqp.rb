module DTK
  class Error
    class AMQP < self
      r8_nested_require('amqp','queue_does_not_exist')
      def to_s
        'AMQP error'
      end
    end
  end
end
