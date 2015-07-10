module DTK
  class ModuleDSL
    class V2 < self
      r8_nested_require('v2', 'parser')
      r8_nested_require('v2', 'dsl_object')
      r8_nested_require('v2', 'object_model_form')
      r8_nested_require('v2', 'incremental_generator')
      def self.normalize(input_hash)
        object_model_form.convert(object_model_form::InputHash.new(input_hash))
      end

      def self.convert_attribute_mapping_helper(input_am, base_cmp, dep_cmp, opts = {})
        object_model_form.convert_attribute_mapping(input_am, base_cmp, dep_cmp, opts)
      end

      private

      # 'self:: form' used below because for example v3 subclasses from v2 and it includes V3::ObjectModelForm
      def self.object_model_form
        self::ObjectModelForm
      end
    end
  end
end
