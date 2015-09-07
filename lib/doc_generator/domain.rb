module DTK
  class DocGenerator
    class Domain
      r8_nested_require('domain', 'active_support_instance_variables')
      r8_nested_require('domain', 'component_module')
      
      extend ActiveSupportInstanceVariablesMixin
      
      def self.normalize_top(dsl_object)
        if dsl_object.kind_of?(ModuleDSL)
          ComponentModule.normalize_top(dsl_object)
        else
          fail Error, "Normalize dsl object of type '#{dsl_object.class}' is not treated"
        end
      end
      
      def self.normalize(*args)
        active_support_instance_values(new(*args))
      end
    end
  end
end

