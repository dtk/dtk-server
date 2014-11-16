module DTK; class AttributeLink
  class Function
    class EqIndexed < Base
      # called when it is an equlaity setting between indexed values on input and output side. 
      # Can be the null index on one of the sides meaning to take whole value
      # TODO: can simplify because only will be called when input is not an array
      def internal_hash_form(opts={})
        output_value = output_value(opts)
        if @index_map.nil? and (@input_path.nil? or @input_path.empty?) and (@output_path.nil? or @output_path.empty?)
          new_rows = output_value.nil? ? [nil] : (output_semantic_type().is_array? ?  output_value : [output_value])
          OutputArrayAppend.new(:array_slice => new_rows, 
                                :attr_link_id => @attr_link_id)
        else
          index_map_persisted = @index_map ? true : false
          index_map = @index_map || IndexMap.generate_from_paths(@input_path,@output_path)
          OutputPartial.new(:attr_link_id => @attr_link_id, 
                            :output_value => output_value, 
                            :index_map => index_map, 
                            :index_map_persisted => index_map_persisted)
        end
      end
      
    end
  end
end; end
