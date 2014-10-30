module DTK
  class ServiceNodeGroup < Node
    def add_group_members(new_cardinality)
      target = get_target()
      assembly = get_assembly?() 

      ndx_new_tr_idhs = TargetRef::Input::BaseNodes.create_linked_target_refs?(target,assembly,[self],:new_cardinality => new_cardinality)
      unless new_tr_idhs = ndx_new_tr_idhs && ndx_new_tr_idhs[id()]
        raise Error.new("Unexpected that new_tr_idhs is empty")
      end

      # find or add state change for node group and then add state change objects for new node members
      node_group_sc = StateChange.create_pending_change_item?(:new_item => id_handle(), :parent => target.id_handle())
      node_group_sc_idh = node_group_sc.id_handle()
      new_items_hash = new_tr_idhs.map{|idh|{:new_item => idh, :parent => node_group_sc_idh}}
      StateChange.create_pending_change_items(new_items_hash)
      new_tr_idhs
    end

    def delete_group_members(new_cardinality)
      node_members = get_node_members()
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

    def get_node_members()
      self.class.get_node_members(id_handle())
    end
    def self.get_node_members(node_group_idh) 
      get_ndx_node_members([node_group_idh]).values.first||[]
    end

    def self.get_ndx_node_members(node_group_idhs)
      ret = Hash.new
      return ret if node_group_idhs.empty?
      sp_hash = {
        :cols => [:id,:display_name,:node_members],
        :filter => [:oneof,:id,node_group_idhs.map{|ng|ng.get_id()}]
      }
      mh = node_group_idhs.first.createMH()
      get_objs(mh,sp_hash).each do |ng|
        node_member = ng[:node_member]
        target = ng[:target]
        node_member.merge!(:target => target) if target
        if index = TargetRef.node_member_index(node_member)
          node_member.merge!(:index => index)
        end
        ndx = ng[:id]
        (ret[ndx] ||= Array.new) << node_member
      end
      ret
    end

    def self.expand_with_node_group_members?(node_or_ngs,opts={})
      ret = node_or_ngs
      ng_idhs = node_or_ngs.select{|n|n.is_node_group?}.map{|n|n.id_handle()}
      if ng_idhs.empty?
        return ret
      end
      ndx_node_members = get_ndx_node_members(ng_idhs)
      ret = Array.new
      if opts[:remove_node_groups]
        node_or_ngs.each do |n|
          if n.is_node_group?
            ret += ndx_node_members[n[:id]]
          else
            ret << n
          end
        end
      else
        node_or_ngs.each do |n|
          ret << n
          ret += ndx_node_members[n[:id]] if n.is_node_group?
        end
      end
      ret
    end

    def self.get_attributes_to_copy_to_target_refs(node_group_idhs)
      Node.get_target_ref_attributes(node_group_idhs,:cols=>CopyToTargetRefAttrs)
    end
    CopyToTargetRefAttrs = (Attribute.common_columns + [:ref,:node_node_id]).uniq - [:id]

    def self.check_valid_id(model_handle,id)
      IdNameHelper.check_valid_id(model_handle,id)
    end
    def self.name_to_id(model_handle,name)
      IdNameHelper.name_to_id(model_handle,name)
    end
    def self.id_to_name(model_handle, id)
      IdNameHelper.id_to_name(model_handle, id)
    end

    def destroy_and_delete(opts={})
      get_node_members().map{|node|node.destroy_and_delete(opts)}
      delete_object(:members_are_deleted=>true)
    end
    def delete_object(opts={})
      unless opts[:members_are_deleted]
        get_node_members().map{|node|node.delete_object(opts)}
      end
      super(opts)
    end


   private
    module IdNameHelper
      def self.check_valid_id(model_handle,id)
        check_valid_id_helper(model_handle,id,filter(:id => id))
      end
      def self.name_to_id(model_handle,name)
        sp_hash =  {
        :cols => [:id],
        :filter => filter(:display_name => name)
        }
        name_to_id_helper(model_handle,name,sp_hash)
      end
      def self.id_to_name(model_handle, id)
        sp_hash =  {
          :cols => [:display_name],
          :filter => filter(:id => id)
        }
        rows = get_objs(model_handle,sp_hash)
        rows && rows.first[:display_name]
      end

     private
      def self.filter(added_condition_hash)
        FilterBase + [[:eq, added_condition_hash.keys.first,added_condition_hash.values.first]]
      end

      NodeType = 'service_node_group'
      FilterBase = 
        [:and,
         [:eq, :type, NodeType],
         [:neq, :datacenter_datacenter_id, nil]
        ]
    end
  end
end

