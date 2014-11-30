module DTK
  class LinkDefContext
    class Value 
      attr_reader :component
      def initialize(component_ref)
        @component_ref = component_ref
        @component = nil
      end
      
      def self.create(term)
        case term[:type].to_sym
         when :component
          Component.new(term)
         when :component_attribute
          ComponentAttribute.new(term)
         when :node_attribute
          NodeAttribute.new(term)
         when :link_cardinality
          LinkCardinality.new(term)
         else
          Log.error("unexpected type #{type}")
          nil
        end
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

      class Component < self
        def initialize(term)
          super(term[:component_type])
        end
        def value()
          @component
        end
      end

      class ComponentAttribute < self
        attr_reader :attribute_ref
        def initialize(term)
          super(term[:component_type])
          @attribute_ref = term[:attribute_name]
        end
        def set_attribute_value!(attribute)
          @attribute = attribute
        end
        def value()
          @attribute
        end
        def augmented_attribute(node_mappings)
          ret = @attribute
          if @component
            ret = ret.merge(:component => @component)
            if node_id = @component[:node_node_id]
              if node = node_mappings.values.find{|n|n[:id] == node_id}
                ret = ret.merge(:node => node)
              end
            end
          end
          ret
        end

        def update_component_attr_index!(component_attr_index)
          p = component_attr_index[@component_ref] ||= Array.new
          p << {:attribute_name => @attribute_ref, :value_object => self}
        end
      end

      class NodeAttribute < self
        attr_reader :attribute_ref, :node_ref
        def initialize(term)
          super(nil)
          @node_ref = term[:node_name]
          @attribute_ref = term[:attribute_name]
        end
        def set_attribute_value!(attribute)
          @attribute = attribute
        end
        def value()
          @attribute
        end
        def augmented_attribute(node_mappings)
          ret = @attribute
          if @node_ref
            if node = node_mappings[@node_ref.to_sym]
              ret = ret.merge(:node => node)
            end
          end
          ret
        end
      end

      class LinkCardinality < self
        def initialize(term)
          super(term[:component_type])
          @attribute_ref = term[:attribute_name]
        end
        def set_attribute_value!(attr)
          @attribute =  attr
        end
      end
    end
  end
end
