r8_require('base_module')

module DTK
  class ComponentModule < BaseModule
    r8_nested_require('component_module','puppet_forge')
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

   private
    def config_agent_type_default()
      :puppet
    end    
  end
end
