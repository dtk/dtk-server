module DTK; class AttributeLink
  class Function
    class Base < self
      def self.function_name?(function_def)
        function_def.is_a?(String) && function_def.to_sym
      end

      def self.base_link_function(input_attr,output_attr)
        input_type = attribute_index_type__input(input_attr)
        output_type = attribute_index_type__output(output_attr)
        LinkFunctionMatrix[output_type][input_type]
      end
      # first index is output type, second one is input type
      # TODO: DTK-2062; thnk want to get rod of select_one and have an 'error' one that leads to
      # violation in service instance
      LinkFunctionMatrix = {
        scalar: {
          scalar: "eq", indexed: "eq_indexed", array: "array_append"
        },
        indexed: {
          scalar: "eq_indexed", indexed: "eq_indexed", array: "array_append"
        },
        array: {
          scalar: "select_one", indexed: "select_one", array: "eq"
        }
      }

      private

      def self.attribute_index_type__input(attr)
        # TODO: think may need to look at data type inside array
        if attr[:input_path] then :indexed
        else attr[:semantic_type_object].is_array?() ? :array : :scalar
        end
      end

      def self.attribute_index_type__output(attr)
        # TODO: may need to look at data type inside array
        if attr[:output_path] then :indexed
        else attr[:semantic_type_object].is_array?() ? :array : :scalar
        end
      end
    end
  end
end; end
