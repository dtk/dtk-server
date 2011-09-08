module XYZ
  class LinkDefContext
    def initialize()
      #TODO: if needed put in machanism where terms map to same values so only need to set values once
      @term_mappings = Hash.new
      @node_mappings = Hash.new
      @component_attr_index = Hash.new
    end
    def add_ref!(term)
      term_index = term[:term_index]
      value = @term_mappings[term_index] ||= Value.create(term)
      value.update_component_attr_index!(self)
    end

    attr_reader :component_attr_index

   private

    class Value 
      attr_reader :component
      def initialize(component_ref)
        @component_ref = component_ref
        @component = nil
      end
      
      def self.create(term)
        case term[:type].to_sym
         when :component
          ValueComponent.new(term)
         when :component_attribute
          ValueComponentAttribute.new(term)
         when :node_attribute
          ValueNodeAttribute.new(term)
         when :link_cardinality
          ValueLinkCardinality.new(term)
         else
          Log.error("unexpected type #{type}")
          nil
        end
      end

      #no op unless overwritetn
      def update_component_attr_index!(link_def_context)
      end
      #overwritten
      def value()
      end
    end

    class ValueComponent < Value
      def initialize(term)
        super(term[:component_name])
      end
      def value()
        @component
      end
    end

    class ValueComponentAttribute < Value
      attr_reader :attribute_ref
      def initialize(term)
        super(term[:component_name])
        @attribute_ref = term[:attribute_name]
      end
      def value()
        @attribute
      end

      def update_component_attr_index!(link_def_context)
        p = link_def_context.component_attr_index[@component] ||= Array.new
        p << {:attribute_name => @attribute_ref, :value_object => self}
      end
    end

    class ValueNodeAttribute < Value
      attr_reader :attribute_ref, :node_ref
      def initialize(node_ref,attr_ref)
        super(nil)
        @node_ref = term[:node_name]
        @attribute_ref = term[:attribute_name]
      end
      def value()
        @attribute
      end
    end

    class ValueLinkCardinality < Value
      def initialize(term)
        super(term[:component_name])
        @attribute_ref = term[:attribute_name]
      end
    end
  end
end
