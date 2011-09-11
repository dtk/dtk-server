module XYZ
  class LinkDefContext
    def initialize()
      #TODO: if needed put in machanism where terms map to same values so only need to set values once
      @term_mappings = Hash.new
      @node_mappings = Hash.new
      @component_attr_index = Hash.new
    end
    def find_attribute(term_index)
      match = @term_mappings[term_index]
      match && match.value
    end
    def add_ref!(term)
      #TODO: see if there can be name conflicts between different types in which nmay want to prefix with type (type's initials, like CA for componanet attribute)
      term_index = term[:term_index]
      value = @term_mappings[term_index] ||= Value.create(term)
      value.update_component_attr_index!(self)
    end
    def add_ref_component!(component_type)
      term_index = component_type
      value = @term_mappings[term_index] ||= ValueComponent.new(:component_type => component_type)
    end

    attr_reader :component_attr_index

    def set_values!(link,link_defs_info)
      local_cmp_type = link[:local_component_type]
      local_cmp = get_component(local_cmp_type,link_defs_info)
      remote_cmp_type = link[:remote_component_type]
      remote_cmp = get_component(remote_cmp_type,link_defs_info)

      [local_cmp_type,remote_cmp_type].each{|t|add_ref_component!(t)}

      @node_mappings = {
        :local => create_node_object(local_cmp),
        :remote => create_node_object(remote_cmp)
      }
      @term_mappings.values.each do |v| 
        v.set_component_remote_and_local_value!(link,local_cmp,remote_cmp)
      end
      #set component attributes
      attrs_to_get = Hash.new
      @term_mappings.each_value do |v|
        if v.kind_of?(ValueComponentAttribute)
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
    def get_component(component_type,link_defs_info)
      match = link_defs_info.find{|r|component_type == r[:component][:component_type]}
      match && match[:component]
    end

    def create_node_object(component)
      component.id_handle.createIDH(:model_name => :node, :id => component[:node_node_id]).create_object()
    end

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

    def get_and_update_node_virtual_attributes!(attrs_to_get)
      return if attrs_to_get.empty?
      cols = [:id,:value_derived,:value_asserted]
      from_db = Node.get_virtual_attributes(attrs_to_get,cols)
      attrs_to_get.each do |node_id,hash_val|
        next unless node_info = from_db[node_id]
        hash_val[:attribute_info].each do |a|
          attr_name = a[:attribute_name]
          a[:value_object].set_attribute_value!(node_info[attr_name]) if node_info.has_key?(attr_name)
        end
      end
    end

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

      def set_component_remote_and_local_value!(link,local_cmp,remote_cmp)
        return if @component_ref.nil? #would fire if this is a NodeAttribute
        if @component_ref == link[:local_component_type]
          @component = local_cmp
        elsif @component_ref == link[:remote_component_type]
          @component = remote_cmp
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
        super(term[:component_type])
      end
      def value()
        @component
      end
    end

    class ValueComponentAttribute < Value
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
      def set_attribute_value!(attribute)
        @attribute = attribute
      end
      def value()
        @attribute
      end
    end

    class ValueLinkCardinality < Value
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
