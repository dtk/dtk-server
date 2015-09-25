module DTK; class AttributeLink
  class Function
    class IndexedOutput < Base
      # called when output is any array that needs to be indexed to yield appropriate scalar; input is a scalar
      def internal_hash_form(opts = {})
        output_value = output_value(opts)
        if @index_map.nil? && (@output_path.nil? || @output_path.empty?)
          UpdateDelta::IndexedOutput.new(output_attribute: @output_attr, attr_link_id: @attr_link_id)
        else
          raise Error.new("TODO: DTK-2261: need to write")
          index_map_persisted = @index_map ? true : false
          index_map = @index_map || IndexMap.generate_from_paths(@input_path, nil)
          UpdateDelta::Partial.new(attr_link_id: @attr_link_id, output_value: output_value, index_map: index_map, index_map_persisted: index_map_persisted)
        end
      end

    end
  end
end; end
