module DTK; class Task; class Template
  class Action
    class ActionMethod < Hash 
      def initialize(action_def)
        super()
        hash =  {
          method_name: action_def.get_field?(:method_name),
          action_def_id: action_def.id()
        }
        replace(hash)
      end

      def method_name
        self[:method_name]
      end

      def config_agent_type
        ConfigAgent::Type::Symbol.dtk_provider
      end
    end
  end
end; end; end
