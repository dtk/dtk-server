module DTK; class ServiceNodeGroup
  module Clone
    # clone_components_to_members returns array with each element being a cloned component
    # and within that element an attributes filed that has all clone attributes
    # if opts[:node_group_components] then filter to only include components corresponding 
    # to these node_group_components
    def self.clone_components_to_members(node_group,node_members,opts={})
      # TODO: this only returns newly cloned; instead should eb idempotent and return cloned and found 
      get_components_not_cloned(node_group,node_members,opts).map do |pair|
        clone_component(pair.node_group_component,pair.node_group_member)
      end
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
      override_attrs = Hash.new
      clone_copy_output = node_group_member.clone_into(node_group_cmp,override_attrs,clone_opts)
      node_member_cmp = clone_copy_output.objects.first
      level = 1
      attributes = clone_copy_output.children_objects(level,:attribute)
      node_member_cmp.merge(:attributes => attributes)
    end

    ComponentNodePair = Struct.new(:node_group_component,:node_group_member)
    # returns array of ComponentNodePairs where component is node group component and node is node member
    # if opts[:node_group_components] then filter to only include components corresponding 
    # to these node_group_components
    def self.get_components_not_cloned(node_group,node_members,opts={})
      ret = Array.new
      return ret if node_members.empty?()
      node_group_id = node_group.id()
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:node_node_id],
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
      node_members.each do |node_member|
        needed_cmp_ids = ng_cmp_ids - (ndx_cmps[node_member.id]||{}).keys
        needed_cmp_ids.each do |cmp_id|
          ng_cmp = ndx_ng_cmps[cmp_id]
          # node_member is of type Node and we want to use type NodeGroupMember
          node_group_member = NodeGroupMember.create_as(node_member)
          ret << ComponentNodePair.new(ng_cmp,node_group_member)
        end
      end
      ret
    end

  end
end; end

