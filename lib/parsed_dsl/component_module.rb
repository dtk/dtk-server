module DTK
  module ParsedDSL
    class ComponentModule
      def initialize
        @module_dsl_obj = nil
      end

      def raw_hash
        raise_error_if_empty('raw_hash')
        @module_dsl_obj.raw_hash
      end

      def version_normalized_hash
        raise_error_if_empty('version_normalized_hash')
        @module_dsl_obj.version_normalized_hash
      end

      def add(module_dsl_obj)
        Log.error("Unexpected that @module_dsl_obj is already set") if @module_dsl_obj
        @module_dsl_obj = module_dsl_obj
      end

      def empty?
        @module_dsl_obj.nil?
      end

      private

      def raise_error_if_empty(method_name)
        fail Error, "The method '#{method_name}' should not be called when @module_dsl_obj is nil" unless @module_dsl_obj
      end
    end
  end
end
