module DTK
  module ParsedDSL
    r8_nested_require('parsed_dsl', 'component_module')
    r8_nested_require('parsed_dsl', 'service_module')

    def self.create(module_object)
      if module_object.kind_of?(DTK::ComponentModule)
        ComponentModule.new
      elsif module_object.kind_of?(DTK::ServiceModule)
        ServiceModule.new
      else
        fail Error, "Unexpected module_object type '#{module_object.class}'"
      end
    end
  end
end
