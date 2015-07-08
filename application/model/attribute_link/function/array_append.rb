module DTK; class AttributeLink
  class Function
    class ArrayAppend < Base
      # called when input is an array and each link into it appends teh value in
      def internal_hash_form(opts={})
        output_value = output_value(opts)
        if @index_map.nil? && (@input_path.nil? || @input_path.empty?)
          new_rows = output_value.nil? ? [nil] : (output_semantic_type().is_array? ?  output_value : [output_value])
          output_is_array = @output_attr[:semantic_type_object].is_array?()
          OutputArrayAppend.new(array_slice: new_rows, attr_link_id: @attr_link_id, output_is_array: output_is_array)
        else
          index_map_persisted = @index_map ? true : false
          index_map = @index_map || AttributeLink::IndexMap.generate_from_paths(@input_path,nil)
          OutputPartial.new(attr_link_id: @attr_link_id, output_value: output_value, index_map: index_map, index_map_persisted: index_map_persisted)
        end
      end

    end
  end
end; end
