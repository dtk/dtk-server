module DTK; class Node
  class NodeAttribute
    module Cache
      def self.attr_is_set?(node, name)
        (node[CacheKeyOnNode] || {}).key?(name.to_sym)
      end
      def self.get(node, name)
        (node[CacheKeyOnNode] || {})[name.to_sym]
      end
      def self.set!(node, raw_val, field_info)
        name = field_info[:name]
        semantic_data_type = field_info[:semantic_type]
        val =
          if raw_val && semantic_data_type
            Attribute::SemanticDatatype.convert_to_internal_form(semantic_data_type, raw_val)
          else
            raw_val
          end
        (node[CacheKeyOnNode] ||= {})[name.to_sym] = val
      end
      CacheKeyOnNode = :attribute_value_cache
    end
  end
end; end
