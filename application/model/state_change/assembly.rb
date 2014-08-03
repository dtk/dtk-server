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

      # Sorting components on each node by 'ordered_component_ids' field
      sorted_ndx_ret = Array.new
      begin
        ndx_ret.values.each do |component_list|
          ordered_component_ids = component_list.first[:node].get_ordered_component_ids()
          sorted_component_list = Array.new
          component_list.each do |change|
            sorted_component_list[ordered_component_ids.index(change[:component][:id])] = change
          end
          sorted_ndx_ret << sorted_component_list.compact
        end
      rescue Exception => e
        # Sorting components failed. Returning random component order
        return ndx_ret.values
      end
      sorted_ndx_ret
    end

    ##
    # The method node_state_changes returns state changes related to nodes
    def self.node_state_changes(task_action_type,assembly,target_idh,opts={})
      case task_action_type
       when :create_node
        node_state_changes__create_nodes(assembly,target_idh,opts)
       when :power_on_node
        node_state_changes__power_on_nodes(assembly,target_idh,opts)
       else
        raise Error.new("Unexpcted task_action_class (#{task_action_class})")
      end
    end
   private
    def self.node_state_changes__create_nodes(assembly,target_idh,opts={})
      ret = Array.new
      assembly_nodes = assembly.get_nodes()
      return ret if assembly_nodes.empty?

      added_state_change_filters = [[:oneof, :node_id, assembly_nodes.map{|r|r[:id]}]]
      target_mh = target_idh.createMH()
      last_level = pending_create_node(target_mh,[target_idh],:added_filters => added_state_change_filters)
      state_change_mh = target_mh.create_childMH(:state_change)
      while not last_level.empty?
        ret += last_level
        last_level = pending_create_node(state_change_mh,last_level.map{|obj|obj.id_handle()})
      end
      ret
      if opts[:just_leaf_nodes]
        ret.reject{|sc|sc[:node].is_node_group?()}
      end
    end

    def self.node_state_changes__power_on_nodes(assembly,target_idh,opts={})
      ret = Array.new()
      unless opts[:just_leaf_nodes]
        raise Error.new("Only supporting option :just_leaf_nodes")
      end
      nodes = assembly.get_leaf_nodes(:cols => [:id,:display_name,:type,:external_ref,:admin_op_status])
      stopped_nodes = nodes.select{|n|n[:admin_op_status] == "stopped"}
      return ret if stopped_nodes.empty?

      state_change_mh = assembly.model_handle(:state_change)
      stopped_nodes.map do |node|
        hash = {
          :type => "power_on_node",
          :node => node
        }
        create_stub(state_change_mh,hash)
      end
    end
  end
end; end
