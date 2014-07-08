module DTK
  class TestDSL
    r8_require('v2')
    class V3 < V2
      r8_nested_require('v3','object_model_form')
      r8_nested_require('v3','dsl_object')
      r8_nested_require('v3','incremental_generator')
    end
  end
end
