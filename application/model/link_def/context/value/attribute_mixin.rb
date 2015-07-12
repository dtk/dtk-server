module DTK; class LinkDef::Context
  class Value
    module AttributeMixin
      def set_attribute_value!(attribute)
        @attribute = attribute
      end

      def value
        @attribute
      end

      def is_array?
        @attribute[:semantic_type_object].is_array?()
      end

      def node
        @node ||= ret_node()
      end

      def on_node_group?
        node().is_node_group?()
      end

      def service_node_group_cache
        ret = node()
        unless ret.is_node_group?()
          fail Error.new('Shoud not be called if not node group')
        end
        ret
      end
    end
  end
end; end
