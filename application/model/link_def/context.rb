module DTK
  class LinkDefContext
    r8_nested_require('context','node_mappings')
    r8_nested_require('context','node_group_member')
    r8_nested_require('context','value')

    def self.create(link,link_defs_info)
      new(link,link_defs_info)
    end

    def initialize(link,link_defs_info)
      @type = nil # can by :internal | :node_to_node | :node_to_node_group
      @node_member_contexts = Hash.new
      @term_mappings = Hash.new
      @node_mappings = Hash.new
      @component_attr_index = Hash.new
      # TODO: add back in commented out parts
      # constraints.each{|cnstr|cnstr.get_context_refs!(ret)}
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
      @term_mappings[term_index] ||= Value::Component.new(:component_type => component_type)
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
    #TODO: WasForInventoryNodeGroup; may deprecate
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
      # TODO: WasForInventoryNodeGroup; may deprecate
      # case @node_mappings.num_node_groups()
      #   when 0 then set_values__node_to_node!(link,cmp_mappings)
      #   when 1 then set_values__node_to_node_group!(link,cmp_mappings)
      #   when 2 
      #  if @node_mappings.is_internal?
      #    set_values__internal!(link,cmp_mappings) 
      #  else 
      #    raise Error.new("Not treating port link between two node groups")
      #  end
      # end
      # substituted below for above
      set_values__node_to_node!(link,cmp_mappings)
    end

    def set_values__internal!(link,cmp_mappings)
      @type = :internal
      set_values__node_to_node!(link,cmp_mappings)
    end

    # TODO: WasForInventoryNodeGroup; may deprecate
    # def set_values__node_to_node_group!(link,cmp_mappings)
    #  @type =  :node_to_node_group
    #  # creates a link def context for each node to node member pair
    #  @node_member_contexts = NodeGroupMember.create_node_member_contexts(link,@node_mappings,cmp_mappings)

    #  # below is needed so that create can have ref to component
    #  @term_mappings.values.each do |v| 
    #    v.set_component_remote_and_local_value!(link,cmp_mappings)
    #  end
    # end

    def set_values__node_to_node!(link,cmp_mappings)
      @type ||= :node_to_node
      @term_mappings.values.each do |v| 
        v.set_component_remote_and_local_value!(link,cmp_mappings)
      end
      # set component attributes
      attrs_to_get = Hash.new
      @term_mappings.each_value do |v|
        if v.kind_of?(Value::ComponentAttribute)
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
        if v.kind_of?(Value::NodeAttribute)
          unless node = @node_mappings[v.node_ref.to_sym]
            Log.error("cannot find node associated with node ref")
            next
          end
          if node.is_node_group?()
            # TODO: put in logic to treat this case by getting attributes on node members and doing fan in mapping
            # to input (which wil be restricted to by a non node group)
            raise ErrorUsage.new("Not treating link from a node attribute (#{v.attribute_ref}) on a node group (#{node[:display_name]})")
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
  end
end
