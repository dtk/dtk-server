module DTK
  class DocGenerator
    class Domain
      r8_nested_require('domain', 'active_support_instance_variables')
      r8_nested_require('domain', 'component_module')
      
      extend ActiveSupportInstanceVariablesMixin
      
      def self.normalize_top(parsed_dsl)
        if parsed_dsl.kind_of?(ParsedDSL::ComponentModule)
          ComponentModule.normalize_top(parsed_dsl)
        else
          fail Error, "Normalize dsl object of type '#{parsed_dsl.class}' is not treated"
        end
      end
      
      def self.normalize(*args)
        active_support_instance_values(new(*args))
      end
    end
  end
end

