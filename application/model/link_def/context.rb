module XYZ
  class LinkDefContext
    def self.create(link,link_defs_info)
      new(link,link_defs_info)
    end

    def initialize(link,link_defs_info)
      #TODO: if needed put in machanism where terms map to same values so only need to set values once
      @type = nil # can by :node_to_node | :node_to_node_group
      @node_members_context = Hash.new
      @term_mappings = Hash.new
      @node_mappings = Hash.new
      @component_attr_index = Hash.new
      #TODO: add back in commented out parts
      # constraints.each{|cnstr|cnstr.get_context_refs!(ret)}
      #TODO: this is making too many assumptions about form of link_defs_info
      #and that self has field local_component_type
      link.attribute_mappings.each do |am|
        add_ref!(am[:input])
        add_ref!(am[:output])
      end

      set_values!(link,link_defs_info)
    end
    private :initialize

    def find_attribute(term_index)
      match = @term_mappings[term_index]
      match && match.value
    end
    def find_component(term_index)
      match = @term_mappings[term_index]
      match && match.value
    end
    def remote_node()
      @node_mappings[:remote]
    end
    def local_node()
      @node_mappings[:local]
    end

    def add_component_ref_and_value!(component_type,component)
      add_ref_component!(component_type).set_component_value!(component)

      #update all attributes that ref this component
      cmp_id = component[:id]
      attrs_to_get = {cmp_id => {:component => component, :attribute_info => @component_attr_index[component_type]}}
      get_and_update_component_virtual_attributes!(attrs_to_get)
    end

    def add_ref!(term)
      #TODO: see if there can be name conflicts between different types in which nmay want to prefix with type (type's initials, like CA for componanet attribute)
      term_index = term[:term_index]
      value = @term_mappings[term_index] ||= Value.create(term)
      value.update_component_attr_index!(self)
    end
    def add_ref_component!(component_type)
      term_index = component_type
      @term_mappings[term_index] ||= ValueComponent.new(:component_type => component_type)
    end

    attr_reader :component_attr_index

   private
    def set_values!(link,link_defs_info)
      local_cmp_type = link[:local_component_type]
      local_cmp = get_component(local_cmp_type,link_defs_info)
      remote_cmp_type = link[:remote_component_type]
      remote_cmp = get_component(remote_cmp_type,link_defs_info)

      [local_cmp_type,remote_cmp_type].each{|t|add_ref_component!(t)}

      @node_mappings = get_node_mappings(local_cmp,remote_cmp)
      num_ngs = @node_mappings.values.inject(0){|s,n|n.is_node_group? ? s+1 : s}
      case num_ngs
        when 0 then set_values__node_to_node!(link,local_cmp,remote_cmp)
        when 1 then set_values__node_to_node_group!(link,local_cmp,remote_cmp)
        when 2 then raise Error.new("Not treating port link between two node groups")
      end
    end

    def set_values__node_to_node_group!(link,local_cmp,remote_cmp)
      @type =  :node_to_node_group
      #TODO: stub
      pp [:node_to_node_group_link, @node_mappings]
      set_values__node_to_node!(link,local_cmp,remote_cmp)
    end

    def set_values__node_to_node!(link,local_cmp,remote_cmp)
      @type ||= :node_to_node
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
          node = @node_mappings[v.node_ref.to_sym]
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

    def get_component(component_type,link_defs_info)
      match = link_defs_info.find{|r|component_type == r[:component][:component_type]}
      unless ret = match && match[:component]
        Log.error("component of type #{component_type} not found in  link_defs_info")
      end
      ret
    end

    def get_node_mappings(local_cmp,remote_cmp)
      node_mh = local_cmp.model_handle(:node)
      local_n_id = local_cmp[:node_node_id]
      remote_n_id = remote_cmp[:node_node_id]
      node_ng_info = Node.get_node_or_ng_summary(node_mh,[local_n_id,remote_n_id])
      {
        :local => node_ng_info[local_n_id],
        :remote => node_ng_info[remote_n_id]
      }
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
    class NodeGroupMember < LinkDefContext 
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

      def set_component_value!(component)
        @component = component
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
