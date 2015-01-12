module DTK
  class ComponentModule < BaseModule
    def self.model_type()
      :component_module
    end
    def self.component_type()
      :puppet #hardwired
    end
    def component_type()
      :puppet #hardwired
    end

    def self.module_specific_type(config_agent_type)
      config_agent_type
    end

    class DSLParser < DTK::ModuleDSLParser
      def self.module_type()
        :component_module
      end
      def self.module_class
        ModuleDSL
      end
    end
  end
end
