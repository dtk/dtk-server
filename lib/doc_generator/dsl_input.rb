module DTK
  class DocGenerator
    class DslInput
      def initialize(dsl_object)
        @raw_dsl_hash        = dsl_object.raw_dsl_hash
        @version_normalized_dsl_hash = dsl_object.version_normalized_dsl_hash
      end

      def normalize_for_document_template
        # TODO: stub
        Domain.normalize(@raw_dsl_hash)
      end
      
    end
  end
end
