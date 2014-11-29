module DTK
  class LinkDefContext
    r8_nested_require('context','term_mappings')
    r8_nested_require('context','node_mappings')
    r8_nested_require('context','node_group_member')
    r8_nested_require('context','value')

    def self.create(link,link_defs_info)
      new(link,link_defs_info)
    end

    def initialize(link,link_defs_info)
      @type = nil # can by :internal | :between_nodes | :contains_nodegroup
      @node_member_contexts = Hash.new
      @term_mappings = TermMappings.new
      @node_mappings = Hash.new
      @component_attr_index = Hash.new
      # TODO: add back in commented out parts
      # constraints.each{|cnstr|cnstr.get_context_refs!(ret)}

      @term_mappings.add_attribute_refs!(@component_attr_index,link.attribute_mappings)

      set_values!(link,link_defs_info)
    end
    private :initialize

    def find_attribute(term_index)
      @term_mappings.find_attribute(term_index)
    end

    def find_component(term_index)
      @term_mappings.find_component(term_index)
    end

    def has_node_group_form?()
      @type == :contains_nodegroup
    end

    def node_group_contexts_array()
      @node_member_contexts.values
    end

    def remote_node()
      @node_mappings.remote
    end
    def local_node()
      @node_mappings.local
    end

    def add_component_ref_and_value!(component_type,component)
      if has_node_group_form?()
        add_component_ref_and_value__node_group!(component_type,component)
      else
        add_component_ref_and_value__node!(component_type,component)
      end
    end

   protected
    def add_component_ref_and_value__node!(component_type,component)
      @term_mappings.add_ref_component!(component_type).set_component_value!(component)
      # update all attributes that ref this component
      cmp_id = component[:id]
      attrs_to_get = {cmp_id => {:component => component, :attribute_info => @component_attr_index[component_type]}}
      get_and_update_component_virtual_attributes!(attrs_to_get)
    end

   private
    #TODO: WasForInventoryNodeGroup; may deprecate
    def add_component_ref_and_value__node_group!(component_type,ng_component)
      # TODO: dont think needed @term_mappings.add_ref_component!(component_type).set_component_value!(component) 
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

      [local_cmp_type,remote_cmp_type].each{|t|@term_mappings.add_ref_component!(t)}

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
    #  @type =  :contains_nodegroup
    #  # creates a link def context for each node to node member pair
    #  @node_member_contexts = NodeGroupMember.create_node_member_contexts(link,@node_mappings,cmp_mappings)

    #  # below is needed so that create can have ref to component
    #  @term_mappings.values.each do |v| 
    #    v.set_component_remote_and_local_value!(link,cmp_mappings)
    #  end
    # end

    # this updates term mappings
    def set_values__node_to_node!(link,cmp_mappings)
      @type ||= :between_nodes
      # set components
      @term_mappings.set_components!(link,cmp_mappings)

      # set component attributes
      attrs_to_set = @term_mappings.component_attributes_to_set()
      get_and_update_component_virtual_attributes!(attrs_to_set)

      # set node attributes
      attrs_to_set = @term_mappings.node_attributes_to_set(@node_mappings)
      get_and_update_node_virtual_attributes!(attrs_to_set)
      self
    end

    def get_component(component_type,link_defs_info)
      match = link_defs_info.find{|r|component_type == r[:component][:component_type]}
      unless ret = match && match[:component]
        Log.error("component of type #{component_type} not found in  link_defs_info")
      end
      ret
    end

    def get_and_update_component_virtual_attributes!(attrs_to_set)
      return if attrs_to_set.empty?
      # TODO: prune which of these data type attributes needed; longer term is to clean them up to be normalized
      cols = [:id,:value_derived,:value_asserted,:data_type,:semantic_data_type,:semantic_type,:semantic_type_summary]
      from_db = Component.get_virtual_attributes__include_mixins(attrs_to_set,cols)
      attrs_to_set.each do |component_id,hash_val|
        next unless cmp_info = from_db[component_id]
        hash_val[:attribute_info].each do |a|
          attr_name = a[:attribute_name]
          a[:value_object].set_attribute_value!(cmp_info[attr_name]) if cmp_info.has_key?(attr_name)
        end
      end
    end

    def get_and_update_node_virtual_attributes!(attrs_to_set)
      return if attrs_to_set.empty?
      cols = [:id,:value_derived,:value_asserted]
      from_db = Node.get_virtual_attributes(attrs_to_set,cols)
      attrs_to_set.each do |node_id,hash_val|
        next unless node_info = from_db[node_id]
        hash_val[:attribute_info].each do |a|
          attr_name = a[:attribute_name]
          a[:value_object].set_attribute_value!(node_info[attr_name]) if node_info.has_key?(attr_name)
        end
      end
    end
  end
end
