module DTK; class ComponentDSL; class V3
  OMFBase = ComponentDSL::V2::ObjectModelForm                                  
  class ObjectModelForm < OMFBase
    r8_nested_require('object_model_form','parsing_error')
    r8_nested_require('object_model_form','component')
    r8_nested_require('object_model_form','choice')

   private
    def context(input_hash)
      ret = super
      if module_level_includes = input_hash["includes"]
        ret.merge!(:module_level_includes => module_level_includes)
      end
      ret
    end
  end
end; end; end
