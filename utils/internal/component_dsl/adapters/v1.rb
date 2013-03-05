module DTK
  class ComponentDSL
    class V1 < self
      r8_nested_require('v1','parser')
      r8_nested_require('v1','dsl_object')
      def self.parse_check(input_hash)
        #TODO: stub
      end
      def self.normalize(input_hash)
pp input_hash
        input_hash
      end
    end
  end
end
