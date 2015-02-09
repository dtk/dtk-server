module DTK; class Task; class Template
  class Action
    class ActionMethod < Hash
      # opts will have keys
      # :method_name
      # TODO: treatkey(s) in opts for params on method
      def initialize(opts={})
        super()
        unless opts[:method_name]
          raise Error.new("should not be called with opts[:method_name].nil?")
        end
        self[:name] = opts[:method_name]
      end

      def config_agent_type()
        :dtk_provider
      end
    end
  end
end; end; end
