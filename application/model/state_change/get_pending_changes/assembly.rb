module DTK; class StateChange
  class Assembly < self
    def self.component_state_changes(assembly,component_type=nil)
      filter = [:and, [:eq, :assembly_id, assembly[:id]]]
      if (component_type == :smoketest)
        filter << [:eq, :basic_type, "smoketest"]
      else
        filter << [:neq, :basic_type, "smoketest"]
      end
      sp_hash = {
        :cols => DTK::Component::pending_changes_cols,
        :filter => filter
      }
      state_change_mh = assembly.model_handle(:state_change)
      changes = get_objs(assembly.model_handle(:component),sp_hash).map do |cmp|
        node = cmp.delete(:node)
        hash = {
          :type => "converge_component",
          :component => cmp,
          :node => node
        }
        create_stub(state_change_mh,hash)
      end
      ##group by node id
      ndx_ret = Hash.new
      changes.each do |sc|
        node_id = sc[:node][:id]
        (ndx_ret[node_id] ||= Array.new) << sc
      end
      ndx_ret.values
    end

    #no generate option needed for node state changes
    def self.node_state_changes(assembly,target_idh)
      changes = Array.new
      assembly_nodes = assembly.get_nodes()
      return changes if assembly_nodes.empty?

      added_state_change_filters = [[:oneof, :node_id, assembly_nodes.map{|r|r[:id]}]]
      target_mh = target_idh.createMH()
      last_level = pending_create_node(target_mh,[target_idh],:added_filters => added_state_change_filters)
      state_change_mh = target_mh.create_childMH(:state_change)
      while not last_level.empty?
        changes += last_level
        last_level = pending_create_node(state_change_mh,last_level.map{|obj|obj.id_handle()},:added_filters => added_state_change_filters)
      end
      ##group by node id (and using fact that each wil be unique id)
      changes.map{|ch|[ch]}
    end
  end
end; end
