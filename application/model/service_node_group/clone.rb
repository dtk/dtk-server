module DTK; class ServiceNodeGroup
  module Clone
    # clone_components_to_members returns array with each element being a cloned component
    # on node_members with their attributes; it clones if necssary
    # if opts[:node_group_components] then filter to only include components corresponding 
    # to these node_group_components
    def self.clone_and_get_components_with_attrs(node_group,node_members,opts={})
      needs_cloning, cloned_components = determine_cloned_components(node_group,node_members,opts)
      ret = needs_cloning.map do |pair|
        clone_component(pair.node_group_component,pair.node_group_member)
      end
      unless cloned_components.empty?
        ret += get_components_with_attributes(cloned_components)
      end
      ret
    end

   private
    # returns a cloned component with a field :attributes, which has all the components attributes
    def self.clone_component(node_group_cmp,node_group_member)
      clone_opts = {
        :include_list => [:attribute],
        :ret_new_obj_with_cols => [:id,:group_id,:display_name],
        :ret_clone_copy_output => true,
        :no_violation_checking => true
      }
#      override_attrs = {:attribute => {:hidden => true}}
      override_attrs = Hash.new
      clone_copy_output = node_group_member.clone_into(node_group_cmp,override_attrs,clone_opts)
      node_member_cmp = clone_copy_output.objects.first
      level = 1
      attributes = clone_copy_output.children_objects(level,:attribute)
      node_member_cmp.merge(:attributes => attributes)
    end

    ComponentNodePair = Struct.new(:node_group_component,:node_group_member)
    # returns two arrays [needs_cloning, cloned_components]
    # needs_cloning has elements of type ComponentNodePairs 
    #   where component is node group component and node is node member
    # cloned_components is array with cloned components 
    # if opts[:node_group_components] then filter to only include components corresponding 
    # to these node_group_components
    def self.determine_cloned_components(node_group,node_members,opts)
      needs_cloning, cloned_components = [], []
      ret = [needs_cloning, cloned_components]
      return ret if node_members.empty?()
      node_group_id = node_group.id()
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:node_node_id,:ancestor_id],
        :filter => [:oneof, :node_node_id, node_members.map{|n|n.id}+[node_group_id]]
      }
      # ndx_cmps is double indexed by [node_id][cmp_id]
      ndx_cmps = Hash.new
      cmp_mh = node_group.model_handle(:component)
      Model.get_objs(cmp_mh,sp_hash).each do |cmp|
        node_id = cmp[:node_node_id]
        cmp_id = cmp[:id]
        (ndx_cmps[node_id] ||= Hash.new).merge!(cmp_id => cmp)
      end

      ndx_ng_cmps = ndx_cmps[node_group_id]||{}
      ng_cmp_ids = ndx_ng_cmps.keys
      if restricted_cmps = opts[:node_group_components]
        ng_cmp_ids = ng_cmp_ids & restricted_cmps.map{|r|r.id} 
      end

      return ret if ng_cmp_ids.empty?

      node_members.each do |node|
        # for each node group component id see if there is a corresponding component on
        # the node (member) by looking at if there is cloned component that has
        # ancestor_id as as matching ng_cmp_id
        #
        # To enable this compute an ndx that takes ancestor_id to cmp_id;
        # this is possible because cmps_on_node has unique ancestor_ids
        cmps_on_node = (ndx_cmps[node.id]||{}).values
        ndx_ancestor_id_to_cmp = cmps_on_node.inject(Hash.new){|h,r|h.merge(r[:ancestor_id] => r)}
        ng_cmp_ids.each do |ng_cmp_id|
          if cloned_cmp = ndx_ancestor_id_to_cmp[ng_cmp_id]
            cloned_components << cloned_cmp
          else
            ng_cmp = ndx_ng_cmps[ng_cmp_id]
            # node is of type Node and we want to use type NodeGroupMember
            node_group_member = NodeGroupMember.create_as(node)
            needs_cloning << ComponentNodePair.new(ng_cmp,node_group_member)
          end
        end
      end
      ret
    end

    def self.get_components_with_attributes(components)
      ret = Array.new
      return ret if components.empty?
      ndx_cmps = components.inject(Hash.new) do |h,cmp|
        h.merge(cmp[:id] => cmp.merge(:attributes => Array.new))
      end
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_component_id],
        :filter => [:oneof,:component_component_id,ndx_cmps.keys]
      }
      attr_mh = components.first.model_handle(:attribute)
      Model.get_objs(attr_mh,sp_hash).each do |attr|
        ndx = attr[:component_component_id]
        ndx_cmps[ndx][:attributes] << attr
      end
      ndx_cmps.values
    end

  end
end; end

