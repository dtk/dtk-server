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

    def set_values!(link,link_defs_info)
      link_defs_info
return

#TODO: old fn taht needs to be refactored
      [link_info[:local_type],link_info[:remote_type]].each{|t|add_ref!(:component,t,t)}


      @node_mappings = {
        :local => create_node_object(local_cmp),
        :remote => create_node_object(remote_cmp)
      }
      @term_mappings.values.each do |v| 
        v.set_component_remote_and_local_value!(link_info,local_cmp,remote_cmp)
      end
      #set (component) attributes
      attrs_to_get = Hash.new
      @term_mappings.each_value do |v|
        if v.kind_of?(ValueAttribute)
          #v.component can be null if refers to component created by an event
          next unless cmp = v.component
          a = (attrs_to_get[cmp[:id]] ||= {:component => cmp, :attribute_info => Array.new})[:attribute_info]
          a << {:attribute_name => v.attribute_ref.to_s, :value_object => v}
        end
      end
      get_and_update_component_virtual_attributes!(attrs_to_get)

      #set node attributes
      attrs_to_get = Hash.new
      @term_mappings.each_value do |v|
        if v.kind_of?(ValueNodeAttribute)
          node = @node_mappings[v.node_ref]
          unless node
            Log.error("cannot find node associated with node ref")
            next
          end
          a = (attrs_to_get[node[:id]] ||= {:node => node, :attribute_info => Array.new})[:attribute_info]
          a << {:attribute_name => v.attribute_ref.to_s, :value_object => v}
        end
      end
      get_and_update_node_virtual_attributes!(attrs_to_get)

      self
    end

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
        p = link_def_context.component_attr_index[@component_ref] ||= Array.new
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
