r8_require('base_module')

module DTK
  class ComponentModule < BaseModule
    # context can be string in which case it is namespace
    # otherwise its a hash whith possible keys :namespace and :assembly
    def self.name_to_id(model_handle,name,context)
      namespace =  assembly = nil
      if context.kind_of?(String)
        namespace = context
      elsif context.kind_of?(Hash)
        namespace = context[:namespace]
        assembly = context[:assembly]
      else
        eaise Error.new("Unexpected argument for context: #{context.inspect}")
      end
pp [namespace, assembly]
      if namespace 
        super(model_handle,name,namespace)
      else 
        unless assembly
          raise Error.new("If no namespace is given an assembly instance must be given")
        end
        unless match = assembly.get_component_modules().find{|r|r[:display_name] == name}
          raise ErrorNameDoesNotExist.new(name,pp_object_type())
        end
        match[:id]
      end
    end

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

   private
    def config_agent_type_default()
      :puppet
    end    
  end
end
