module XYZ
  class LinkDefContext
    def self.create(link,link_defs_info)
      new(link,link_defs_info)
    end

    def initialize(link,link_defs_info)
      # TODO: if needed put in machanism where terms map to same values so only need to set values once
      @type = nil # can by :internal | :node_to_node | :node_to_node_group
      @node_member_contexts = Hash.new
      @term_mappings = Hash.new
      @node_mappings = Hash.new
      @component_attr_index = Hash.new
      # TODO: add back in commented out parts
      # constraints.each{|cnstr|cnstr.get_context_refs!(ret)}
      # TODO: this is making too many assumptions about form of link_defs_info
      # and that self has field local_component_type
      link.attribute_mappings.each do |am|
        add_ref!(am[:input])
        add_ref!(am[:output])
      end

      set_values!(link,link_defs_info)
    end
    private :initialize

    def has_node_group_form?()
      @type == :node_to_node_group
    end

    def node_group_contexts_array()
      @node_member_contexts.values
    end

    def find_attribute(term_index)
      match = @term_mappings[term_index]
      match && match.value
    end
    def find_component(term_index)
      match = @term_mappings[term_index]
      match && match.value
    end
    def remote_node()
      @node_mappings.remote
    end
    def local_node()
      @node_mappings.local
    end

    def add_ref!(term)
      # TODO: see if there can be name conflicts between different types in which nmay want to prefix with type (type's initials, like CA for componanet attribute)
      term_index = term[:term_index]
      value = @term_mappings[term_index] ||= Value.create(term)
      value.update_component_attr_index!(self)
    end
    def add_ref_component!(component_type)
      term_index = component_type
      @term_mappings[term_index] ||= ValueComponent.new(:component_type => component_type)
    end

    attr_reader :component_attr_index

    def add_component_ref_and_value!(component_type,component)
      if has_node_group_form?()
        add_component_ref_and_value__node_group!(component_type,component)
      else
        add_component_ref_and_value__node!(component_type,component)
      end
    end


   protected
    def add_component_ref_and_value__node!(component_type,component)
      add_ref_component!(component_type).set_component_value!(component)
      # update all attributes that ref this component
      cmp_id = component[:id]
      attrs_to_get = {cmp_id => {:component => component, :attribute_info => @component_attr_index[component_type]}}
      get_and_update_component_virtual_attributes!(attrs_to_get)
    end

   private
    def add_component_ref_and_value__node_group!(component_type,ng_component)
      # TODO: dont think needed add_ref_component!(component_type).set_component_value!(component) 
      # TODO: may be more efficient to do this in bulk
      # get corresponding components on node group members
      node_ids = @node_member_contexts.keys
      ndx_node_cmps = NodeGroupMember.get_node_member_components(node_ids,ng_component).inject({}) do |h,r|
        h.merge(r[:node_node_id] => r)
      end
      @node_member_contexts.each do |node_id,member_context|
        node_cmp = ndx_node_cmps[node_id]
        member_context.add_component_ref_and_value__node!(component_type,node_cmp)
      end
    end

    def set_values!(link,link_defs_info)
      local_cmp_type = link[:local_component_type]
      local_cmp = get_component(local_cmp_type,link_defs_info)
      remote_cmp_type = link[:remote_component_type]
      remote_cmp = get_component(remote_cmp_type,link_defs_info)

      [local_cmp_type,remote_cmp_type].each{|t|add_ref_component!(t)}

      cmp_mappings = {:local => local_cmp, :remote => remote_cmp}
      @node_mappings = NodeMappings.create_from_cmp_mappings(cmp_mappings)
      case @node_mappings.num_node_groups()
       when 0 then set_values__node_to_node!(link,cmp_mappings)
       when 1 then set_values__node_to_node_group!(link,cmp_mappings)
       when 2 
        if @node_mappings.is_internal?
          set_values__internal!(link,cmp_mappings) 
        else 
          raise Error.new("Not treating port link between two node groups")
        end
      end
    end
    def set_values__internal!(link,cmp_mappings)
      @type = :internal
      set_values__node_to_node!(link,cmp_mappings)
    end
    def set_values__node_to_node_group!(link,cmp_mappings)
      @type =  :node_to_node_group
      # creates a link def context for each node to node member pair
      @node_member_contexts = NodeGroupMember.create_node_member_contexts(link,@node_mappings,cmp_mappings)

      # below is needed so that create can have ref to component
      @term_mappings.values.each do |v| 
        v.set_component_remote_and_local_value!(link,cmp_mappings)
      end
    end

    def set_values__node_to_node!(link,cmp_mappings)
      @type ||= :node_to_node
      @term_mappings.values.each do |v| 
        v.set_component_remote_and_local_value!(link,cmp_mappings)
      end
      # set component attributes
      attrs_to_get = Hash.new
      @term_mappings.each_value do |v|
        if v.kind_of?(ValueComponentAttribute)
          # v.component can be null if refers to component created by an event
          next unless cmp = v.component
          a = (attrs_to_get[cmp[:id]] ||= {:component => cmp, :attribute_info => Array.new})[:attribute_info]
          a << {:attribute_name => v.attribute_ref.to_s, :value_object => v}
        end
      end
      get_and_update_component_virtual_attributes!(attrs_to_get)

      # set node attributes
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

    class NodeMappings < Hash
      def self.create_from_cmp_mappings(cmp_mappings)
        ndx_node_ids = cmp_mappings.inject({}){|h,(k,v)|h.merge(k => v[:node_node_id])}
        sample_cmp = cmp_mappings[:local]
        node_mh = sample_cmp.model_handle(:node)
        if ndx_node_ids[:local] == ndx_node_ids[:remote] #shortcut if internal
          # since same node on both sides; just create from one of them
          node = node_mh.createIDH(:id => ndx_node_ids[:local]).create_object()
          new(node)
        else
          node_ng_info = Node.get_node_or_ng_summary(node_mh,ndx_node_ids.values)
          new(node_ng_info[ndx_node_ids[:local]],node_ng_info[ndx_node_ids[:remote]])
        end
      end
      
      def num_node_groups()
        values.inject(0){|s,n|n.is_node_group? ? s+1 : s}
      end
      def is_internal?()
        local[:id] == remote[:id]
      end
      def node_group_members()
        ret = Array.new
        if local.is_node_group?()
          ret << {:endpoint => :local, :nodes => local[:node_group_members]}
        end
        if remote.is_node_group?()
          ret << {:endpoint => :remote, :nodes => remote[:node_group_members]}
        end
        ret
      end
      def local()
        self[:local]
      end
      def remote()
        self[:remote]
      end
     private
      def initialize(local,remote=nil)
        super()
        replace(:local => local, :remote => remote||local)
      end
    end

    class NodeGroupMember < LinkDefContext 
      def self.create_node_member_contexts(link,node_mappings,cmp_mappings)
        ret = Hash.new
        ng_members_x = node_mappings.node_group_members()
        unless ng_members_x.size == 1
          raise Error.new("Only one of local or remote should be node group")
        end
        ng_members = ng_members_x.first
        # no op if there is side with cardinality == 0
        if ng_members[:nodes].size == 0
          return ret
        end
        create_node_member_contexts_aux(link,ng_members,cmp_mappings)
      end

      def self.get_node_member_components(node_ids,ng_component)
        cols = ng_component.keys
        cols << :node_node_id unless cols.include?(:node_node_id)
        sp_hash = {
          :cols => cols,
          :filter => [:and, [:oneof, :node_node_id, node_ids], [:eq, :ng_component_id, ng_component[:id]]]
        }
        cmp_mh = ng_component.model_handle
        Model.get_objs(cmp_mh,sp_hash)
      end

      private
      # returns hash where each key is a node member node id and each eleemnt is LinkDefContext relevant to linking node member to other end node
      def self.create_node_member_contexts_aux(link,ng_members,cmp_mappings)
        node_cmp_part = {:component=> cmp_mappings[ng_members[:endpoint] == :local ? :remote : :local] }
        node_ids = ng_members[:nodes].map{|n|n[:id]}
        ng_member_cmps = get_node_member_components(node_ids,cmp_mappings[ng_members[:endpoint]])
        ng_member_cmps.inject({}) do |ret,ng_member_cmp|
          link_defs_info = [node_cmp_part, {:component=>ng_member_cmp}]
          link_def_context = new(link,link_defs_info)
          ret.merge(ng_member_cmp[:node_node_id] => link_def_context)
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
      def update_component_attr_index!(link_def_context)
      end
      # overwritten
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
