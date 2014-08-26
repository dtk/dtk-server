r8_require('base_module')

module DTK
  class NodeModule < BaseModule

    def self.model_type()
      :node_module
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

   private
    def config_agent_type_default()
      :puppet
    end
  end
end