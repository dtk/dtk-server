# TODO: need to reconcile or have better names on this versus NodeGroup
module DTK
  # This class represents objects that are specfied by node groups in assembly templates and service insatnces
  # TODO: double check this is accurate description; they capture what Input::BaseNodes is,
  # but maybe not inventory data subclass
  class ServiceNodeGroup < Node
    r8_nested_require('service_node_group','id_name_helper')
    r8_nested_require('service_node_group','clone')
    r8_nested_require('service_node_group','node_group_member')
    r8_nested_require('service_node_group','cache')

    def self.check_valid_id(model_handle,id)
      IdNameHelper.check_valid_id(model_handle,id)
    end
    def self.name_to_id(model_handle,name)
      IdNameHelper.name_to_id(model_handle,name)
    end
    def self.id_to_name(model_handle, id)
      IdNameHelper.id_to_name(model_handle, id)
    end

    # clone_components_to_members returns array with each element being a cloned component
    # on node_members with their attributes; it clones if necssary
    # if opts[:node_group_components] then filter to only include components corresponding
    # to these node_group_components
    def clone_and_get_components_with_attrs(node_members,opts={})
      Clone.clone_and_get_components_with_attrs(self,node_members,opts)
    end

    # called when bumping up cardinaility in a service instance
    def add_group_members(new_cardinality)
      target = get_target()
      assembly = get_assembly?()
      new_tr_idhs = nil
      Transaction do
        ndx_new_tr_idhs = TargetRef::Input::BaseNodes.create_linked_target_refs?(target,assembly,[self],new_cardinality: new_cardinality)
        unless new_tr_idhs = ndx_new_tr_idhs && ndx_new_tr_idhs[id()]
          raise Error.new("Unexpected that new_tr_idhs is empty")
        end

        # add attribute mappings, cloning if needed
        create_attribute_links__clone_if_needed(target,new_tr_idhs)

        # find or add state change for node group and then add state change objects for new node members
        node_group_sc = StateChange.create_pending_change_item?(new_item: id_handle(), parent: target.id_handle())
        node_group_sc_idh = node_group_sc.id_handle()
        new_items_hash = new_tr_idhs.map{|idh|{new_item: idh, parent: node_group_sc_idh}}
        StateChange.create_pending_change_items(new_items_hash)
      end
      new_tr_idhs
    end

    def delete_group_members(new_cardinality)
      node_members = get_node_group_members()
      num_to_delete = node_members.size - new_cardinality
      # to find ones to delete;
      # first look for  :admin_op_status == pending"
      # then pick ones with highest index
      #TODO: can be more efficient then needing to sort who thing
      sorted = node_members.sort do |a,b|
        a_op = (a[:admin_op_status] ? 1 : 0)
        b_op = (b[:admin_op_status] ? 1 : 0)
        if b_op != a_op
          b_op <=> a_op
        else
          (b[:index]||0) <=> (a[:index]||0)
        end
      end
      to_delete = (0...num_to_delete).map{|i|sorted[i]}
      to_delete.each{|node_group_member|node_group_member.destroy_and_delete()}
    end

    def bump_down_cardinality(amount=1)
      card = attribute.cardinality
      new_card = card - amount
      if new_card < 0
        raise ErrorUsage.new("Existing cardinality (#{card}) is less than amount to decrease it by (#{amount})")
      end
      Node::NodeAttribute.create_or_set_attributes?([self],:cardinality,new_card)
      new_card
    end

    def get_node_group_members
      self.class.get_node_group_members(id_handle())
    end
    def self.get_node_group_members(node_group_idh)
      get_ndx_node_group_members([node_group_idh]).values.first||[]
    end

    def self.get_ndx_node_group_members(node_group_idhs)
      ret = {}
      return ret if node_group_idhs.empty?
      sp_hash = {
        cols: [:id,:display_name,:node_members],
        filter: [:oneof,:id,node_group_idhs.map{|ng|ng.get_id()}]
      }
      mh = node_group_idhs.first.createMH()
      get_objs(mh,sp_hash).each do |ng|
        node_member = ng[:node_member]
        target = ng[:target]
        node_member.merge!(target: target) if target
        if index = TargetRef.node_member_index(node_member)
          node_member.merge!(index: index)
        end
        ndx = ng[:id]
        (ret[ndx] ||= []) << node_member
      end
      ret
    end

    # making robust so checks if node_or_ngs has node groups already
    def self.expand_with_node_group_members?(node_or_ngs,opts={})
      ret = node_or_ngs
      ng_idhs = node_or_ngs.select{|n|n.is_node_group?}.map{|n|n.id_handle()}
      if ng_idhs.empty?
        return ret
      end
      ndx_node_members = get_ndx_node_group_members(ng_idhs)
      ndx_ret = {}
      node_or_ngs.each do |n|
        if n.is_node_group?
          ndx_ret.merge!(n.id => n) unless opts[:remove_node_groups]
          # (ndx_node_members[n[:id]]||[]).each{|n|ndx_ret.merge!(n.id => n)}
          (ndx_node_members[n[:id]]||[]).each do |node|
            if opts[:add_group_member_components]
              components = n.info_about(:components)
              node.merge!(components: components) unless components.empty?
            end
            ndx_ret.merge!(node.id => node)
          end
        else
          ndx_ret.merge!(n.id => n)
        end
      end
      ndx_ret.values
    end

    def self.get_node_groups?(node_or_ngs)
      ndx_ret = {}
      node_or_ngs.each do |n|
        ndx_ret.merge!(n.id => n) if n.is_node_group?
      end

      return (ndx_ret.empty? ? ndx_ret : ndx_ret.values)
    end

    def self.get_node_attributes_to_copy(node_group_idhs)
      Node.get_target_ref_attributes(node_group_idhs,cols: NodeAttributesToCopy)
    end
    NodeAttributesToCopy = (Attribute.common_columns + [:ref,:node_node_id]).uniq - [:id]

    def destroy_and_delete(opts={})
      get_node_group_members().map{|node|node.destroy_and_delete(opts)}
      delete_object(members_are_deleted: true)
    end

    def delete_object(opts={})
      unless opts[:members_are_deleted]
        get_node_group_members().map{|node|node.delete_object(opts)}
      end
      super(opts)
    end

    private

    def create_attribute_links__clone_if_needed(target,target_ref_idhs)
      port_links = get_port_links()
      return if port_links.empty?
      opts_create_links = {set_port_link_temporal_order: true, filter: {target_ref_idhs: target_ref_idhs}}
      port_links.each do |port_link|
        port_link.create_attribute_links__clone_if_needed(target.id_handle,opts_create_links)
      end
    end
  end
end

