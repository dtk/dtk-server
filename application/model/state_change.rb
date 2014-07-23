module DTK
  class StateChange < Model
    r8_nested_require('state_change','get_pending_changes')
    r8_nested_require('state_change','create')
    extend GetPendingChangesClassMixin
    extend CreateClassMixin

    def self.list_pending_changes(target_idh)
      # TODO: may pass in options so dont get all fields that are returned in flat_list_pending_changes
      pending_changes = flat_list_pending_changes(target_idh)
      ndx_ret = Hash.new
      pending_changes.each do |ch|
        node_id = ch[:node][:id]
        node = ndx_ret[node_id] ||= {:node_id => node_id, :node_name => ch[:node][:display_name], :node_changes => Array.new, :ndx_cmp_changes => Hash.new} 
        if ch[:type] == "create_node"
          node[:node_changes] << {:name => ret_display_name(ch)}
        else
          cmp_id = ch[:component][:id]
          cmp = node[:ndx_cmp_changes][cmp_id] ||= {:component_id => cmp_id, :component_name => ch[:component][:display_name], :changes => Array.new}
          # TODO stub
          cmp[:changes] << ret_display_name(ch)
        end
      end
      ndx_ret.values.map do |n|
        changes = n[:node_changes] + n[:ndx_cmp_changes].values
        el = {:node_id => n[:node_id], :node_name => n[:node_name]}
        el.merge!(:node_changes => n[:node_changes]) unless n[:node_changes].empty?
        el.merge!(:component_changes => n[:ndx_cmp_changes].values) unless n[:ndx_cmp_changes].empty?
        el
      end
    end

    # object processing and access functions
    #######################
    def on_node_config_agent_type()
      ret = (self[:component]||{})[:config_agent_type]
      ret && ret.to_sym
    end

    def create_node_config_agent_type()
      # TODO: stub
      :ec2
    end

    def self.state_changes_are_concurrent?(state_change_list)
      rel_order = state_change_list.map{|x|x[:relative_order]}
      val = rel_order.shift
      rel_order.each{|x|return nil unless x == val}
      true
    end

    def self.ret_display_name(flat_pending_ch)
      type = flat_pending_ch[:type]
      node_name = flat_pending_ch[:node][:display_name]
      suffix = 
        case type
         when "create_node"
          node_name
         when "install_component", "update_implementation"
          cmp_name = flat_pending_ch[:component][:display_name]
          "#{node_name}:#{cmp_name}"
         else
          Log.error("need rules to treat type (#{type})")
          nil
        end
      suffix ? "#{type}(#{suffix})" : type
    end
  end
end
