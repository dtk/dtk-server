module DTK; class ModuleDSL; class V4
  OMFBase = ModuleDSL::V3::ObjectModelForm                                  
  class ObjectModelForm < OMFBase
    r8_nested_require('object_model_form','component')
    r8_nested_require('object_model_form','action_def')
  end
end; end; end
