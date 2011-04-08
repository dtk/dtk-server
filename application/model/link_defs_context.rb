module XYZ
  class LinkDefsContext
    def initialize()
      #TODO: if needed put in machanism where terms map to same values so only need to set values once
      @term_mappings = Hash.new
      @node_mappings = Hash.new
      @component_attr_index = Hash.new
    end

    def find_attribute(term_index_x)
      term_index = normalize_term_index(term_index_x)
      match = @term_mappings[term_index]
      match && match.value
    end
    def find_component(term_index_x)
      term_index = normalize_term_index(term_index_x)
      match = @term_mappings[term_index]
      match && match.value
    end
    def remote_node()
      @node_mappings[:remote]
    end
    def local_node()
      @node_mappings[:local]
    end

    def add_ref!(type,term_index_x,*value_ref)
      term_index = normalize_term_index(term_index_x)
      unless @term_mappings.has_key?(term_index)
        @term_mappings[term_index] = 
          case type
           when :component
            ValueComponent.new(*value_ref)
           when :attribute
            cmp_ref = value_ref[0]
            attr_name = value_ref[1].to_s
            v = ValueAttribute.new(*value_ref)
            p = @component_attr_index[cmp_ref] ||= Array.new
            p << {:attribute_name => attr_name,:value_object => v}
            v
           when :link_cardinality
            ValueLinkCardinality.new(*value_ref)
           else
            Log.error("unexpected type #{type}")
            nil
          end
      end
    end

    def add_component_ref_and_value!(cmp_ref,cmp_value)
      term_index = normalize_term_index(cmp_ref)
      add_ref!(:component,term_index,cmp_ref).set_component_value!(cmp_value)

      #update all attributes taht ref this component
      cmp_id = cmp_value[:id]
      attrs_to_get = {cmp_id => {:component => cmp_value, :attribute_info => @component_attr_index[cmp_ref]}}
      get_and_update_component_virtual_attributes!(attrs_to_get)
    end

    def set_values!(link_info,local_cmp,remote_cmp)
      [link_info[:local_type],link_info[:remote_type]].each{|t|add_ref!(:component,t,t)}
      @node_mappings = {
        :local => create_node_object(local_cmp),
        :remote => create_node_object(remote_cmp)
      }
      @term_mappings.values.each do |v| 
        v.set_component_remote_and_local_value!(link_info,local_cmp,remote_cmp)
      end
      #set attrs_to_get
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
      self
    end
   private

    def get_and_update_component_virtual_attributes!(attrs_to_get)
      return if attrs_to_get.empty?
      cols = [:id,:value_derived,:value_asserted]
      from_db = Component.get_virtual_attributes__include_mixins(attrs_to_get,cols)
      attrs_to_get.each do |component_id,hash_val|
        next unless cmp_info = from_db[component_id]
        hash_val[:attribute_info].each do |a|
          attr_name = a[:attribute_name]
          a[:value_object].set_attribute_value!(cmp_info[attr_name]) if cmp_info.has_key?(attr_name)
        end
      end
    end

    def normalize_term_index(t_x)
      t = t_x.to_s
      t =~ /^[^:]/ ? ":#{t}" : t
    end
    
    def create_node_object(component)
      component.id_handle.createIDH(:model_name => :node, :id => component[:node_node_id]).create_object()
    end

    class Value 
      attr_reader :component
      def initialize(component_ref)
        @component_ref = component_ref
        @component = nil
      end

      def set_component_remote_and_local_value!(link_info,local_cmp,remote_cmp)
        if @component_ref == link_info[:local_type]
          @component = local_cmp
        elsif @component_ref == link_info[:remote_type]
          @component = remote_cmp
        else
          Log.error("cannot find ref to component #{@ref}")
        end
      end
      
      def set_component_value!(component)
        @component = component
      end
      #overwrite
      def value()
      end
    end

    class ValueComponent < Value
      def initialize(component_ref)
        super(component_ref)
      end
      def value()
        @component
      end
    end

    class ValueAttribute < Value
      attr_reader :attribute_ref
      def initialize(component_ref,attr_ref)
        super(component_ref)
        @attribute_ref = attr_ref
      end
      def set_attribute_value!(attribute)
        @attribute = attribute
      end
      def value()
        @attribute
      end
    end

    class ValueLinkCardinality < Value
      def initialize(component_ref,attr_ref)
        super(component_ref)
        @attribute_ref = attr_ref
      end
      def set_attribute_value!(attr)
        @attribute =  attr
      end
    end
  end


end
