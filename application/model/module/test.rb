module DTK
  class TestModule < BaseModule

    def self.model_type()
      :test_module
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
        :test_module
      end
      def self.module_class
        ModuleDSL
      end
    end

   private
    def config_agent_type_default()
      :puppet
    end
  end
end
