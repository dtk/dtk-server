module DTK
  class NodeModuleDSL
    class V1 < self
      r8_nested_require('v1','object_model_form')
      def self.parse_check(input_hash)
        # TODO: stub
      end
      def self.normalize(input_hash)
        ObjectModelForm.convert(ObjectModelForm::InputHash.new(input_hash))
      end
    end
  end
end
