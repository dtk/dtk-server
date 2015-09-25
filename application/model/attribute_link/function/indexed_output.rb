module DTK; class AttributeLink
  class Function
    class IndexedOutput < Base
      # called when output is any array that needs to be indexed to yield appropriate scalar; input is a scalar
      def internal_hash_form(opts = {})
        if @output_path and !@output_path.empty?
          raise Error.new("Unexpected that @output_path is not empty")
        end

        output_value = output_value(opts)
        if @index_map.nil?
          UpdateDelta::IndexedOutput.new(output_value: output_value, attr_link_id: @attr_link_id)
        else
          index_map_persisted = true
          UpdateDelta::Partial.new(attr_link_id: @attr_link_id, output_value: output_value, index_map: @index_map, index_map_persisted: index_map_persisted)
        end
      end
    end
  end
end; end
