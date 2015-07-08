module DTK; class ServiceNodeGroup
  class Cache < self
    def self.model_name
      :node
    end

    def self.create_as(node,target_refs)
      super(node).set_target_refs!(target_refs)
    end

    def set_target_refs!(target_refs)
      @target_refs = target_refs
      self
    end

    def get_node_attributes(opts={})
      @node_attributes ||= get_node_attributes_aux(opts)
    end

    # gets component attributes on node members, first cloning components from node group if needed
    def get_component_attributes(node_group_component,opts={})
      # indexed by node_group_component_id
      @ndx_component_attributes ||= {}
      ndx = node_group_component.id()
      cmps_with_attrs = @ndx_component_attributes[ndx] ||= clone_and_get_components_with_attrs(node_group_component,opts)
      cmps_with_attrs.inject([]){|a,cmp|a + cmp[:attributes]}
    end

    private

    def get_node_attributes_aux(opts={})
      target_ref_ids = target_ref_ids?(opts[:filter]) || @target_refs.map{|n|n.id}
      sp_hash = {
        cols: [:id,:group,:display_name,:node_node_id],
        filter: [:oneof, :node_node_id,target_ref_ids]
      }
      attr_mh = model_handle(:attribute)
      Model.get_objs(attr_mh,sp_hash)
    end

    def clone_and_get_components_with_attrs(node_group_component,opts={})
      # clone_components_to_members returns array with each element being a cloned component
      # and within that element an :attributes field that has all clone attributes
      target_refs = @target_refs
      if target_ref_ids = target_ref_ids?(opts[:filter])
        target_refs = target_refs.select{|r|target_ref_ids.include?(r[:id])}
      end
      super(target_refs,node_group_components: [node_group_component])
    end

    def target_ref_ids?(filter=nil)
      filter && (filter[:target_ref_idhs]||[]).map{|idh|idh.get_id()}
    end
  end
end; end

