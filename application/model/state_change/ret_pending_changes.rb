module XYZ
  module RetPendingChangesClassMixin
    def ret_assembly_component_state_changes(assembly_idh,target_idh)
      sp_hash = {
        :cols => [:id,:node_for_state_change_info,:display_name,:basic_type,:external_ref,:node_node_id,:only_one_per_node,:extended_base_id,:implementation_id,:group_id],
        :filter => [:eq, :assembly_id, assembly_idh.get_id()]
      }
      state_change_mh = assembly_idh.createMH(:state_change)
      changes = get_objs(assembly_idh.createMH(:component),sp_hash).map do |cmp|
        node = cmp.delete(:node)
        hash = {
          :type => "converge_component",
          :component => cmp,
          :node => node
        }
        create_stub(state_change_mh,hash)
      end
      [changes]
    end
  end
end
