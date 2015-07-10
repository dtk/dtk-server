module DTK
  class ModuleDSL
    r8_require('v3')
    class V4 < V3
      r8_nested_require('v4', 'object_model_form')
    end
  end
end
