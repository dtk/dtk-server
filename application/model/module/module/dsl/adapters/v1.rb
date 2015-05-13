module DTK
  class ModuleDSL
    class V1 < self
      r8_nested_require('v1','parser')
      r8_nested_require('v1','dsl_object')
      def self.normalize(input_hash)
        input_hash
      end
    end
  end
end
