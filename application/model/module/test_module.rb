module DTK
  class TestModule < Model
    r8_nested_require('component','dsl_mixin')
    r8_nested_require('component','dsl')

    r8_nested_require('component','version_context_info')
    r8_nested_require('component','delete_mixin')

    # include DeleteMixin
    extend ModuleClassMixin
    include ModuleMixin
    # include DSLMixin

    def self.model_type()
      :test_module
    end

    def self.component_type()
      :test #hardwired
    end

    def component_type()
      :test #hardwired
    end
    
  end
end
