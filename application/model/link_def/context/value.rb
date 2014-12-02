module DTK
  class LinkDefContext
    class Value 
      r8_nested_require('value','component')
      r8_nested_require('value','attribute_mixin') # must be before component_attribute and node_attribute
      r8_nested_require('value','component_attribute')
      r8_nested_require('value','node_attribute')
      attr_reader :component
      def initialize(component_ref)
        @component_ref = component_ref
        @component = nil
      end
      
      def self.create(term,opts={})
        case term[:type].to_sym
         when :component
          Component.new(term)
         when :component_attribute
          ComponentAttribute.new(term,opts)
         when :node_attribute
          NodeAttribute.new(term,opts)
         else
          Log.error("unexpected type #{type}")
          nil
        end
      end

      # can be overwritten
      def is_node_attribute?()
        false
      end

      def set_component_remote_and_local_value!(link,cmp_mappings)
        return if @component_ref.nil? #would fire if this is a NodeAttribute
        if @component_ref == link[:local_component_type]
          @component = cmp_mappings[:local]
        elsif @component_ref == link[:remote_component_type]
          @component = cmp_mappings[:remote]
        end
      end

      def set_component_value!(component)
        @component = component
      end

      # no op unless overwritetn
      def update_component_attr_index!(component_attr_index)
      end
      # overwritten
      def value()
      end
    end
  end
end
