module DTK; class Task; class Template
  class Action
    class ActionMethod < Hash
      def initialize(method_hash)
        super()
        replace(method_hash)
      end

      def config_agent_type()
        ConfigAgent::Type::Symbol.dtk_provider
      end
    end
  end
end; end; end
