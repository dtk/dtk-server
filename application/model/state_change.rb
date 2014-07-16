module DTK
  class StateChange < Model
    r8_nested_require('state_change','get_pending_changes')
    extend GetPendingChangesClassMixin

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

    def self.create_converge_state_changes(node_idhs)
      sample_idh = node_idhs.first()
      sp_hash = {
        :cols => [:id,:datacenter_datacenter_id,:components]
      }
      new_item_hashes = Model.get_objs_in_set(node_idhs,sp_hash).map do |r|
        {
          :new_item => r[:component].id_handle(), 
          :parent => sample_idh.createIDH(:model_name => :datacenter, :id=> r[:datacenter_datacenter_id]),
          :type => "converge_component"
        }
      end
      create_pending_change_items(new_item_hashes)
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

    def self.create_pending_change_item(new_item_hash,opts={})
      create_pending_change_items([new_item_hash],opts).first
    end
    # assumption is that all parents are of same type and all changed items of same type
    def self.create_pending_change_items(new_item_hashes,opts={})
      ret = Array.new
      return ret if new_item_hashes.empty? 
      parent_model_name = new_item_hashes.first[:parent][:model_name]

      # workaround referenced in PBUILDER-161
      unless [:target,:datacenter].include?(parent_model_name)
        Log.info("workaround for PBUILDER-161: changing parent_model_name (#{parent_model_name}) to be target (datacenter)")
        parent_idh = new_item_hashes.first[:parent].get_top_container_id_handle(:datacenter)
        parent_model_name = parent_idh[:model_name]
        new_item_hashes.each{|r|r[:parent] = parent_idh}
      end

      new_item_obj = new_item_hashes.first[:new_item]
      new_item_obj.get_field?(:group_id)  #to make sure model handle has group_id
      model_handle = new_item_obj.createMH({:model_name => :state_change, :parent_model_name => parent_model_name})

      object_model_name = new_item_hashes.first[:new_item][:model_name]
      object_id_col = "#{object_model_name}_id".to_sym
      parent_id_col = model_handle.parent_id_field_name()
      type = new_item_hashes.first[:type] ||  
        case object_model_name
          when :attribute then "setting"
          when :component then "install_component"
          when :node then "create_node"
          else raise Error::NotImplemented.new("when object type is #{object_model_name}")
      end 
      
      ref_prefix = "state_change"
      i=0
      rows = new_item_hashes.map do |item| 
        ref = "#{ref_prefix}#{(i+=1).to_s}"
        id = item[:new_item].get_id()
        parent_id = item[:parent].get_id()
        display_name = ret_stub_display_name(object_model_name,item[:new_item][:display_name])
        hash = {
          :ref => ref,
          :display_name => display_name,
          :status => "pending",
          :type => type,
          :object_type => object_model_name.to_s,
          object_id_col => id,
          parent_id_col => parent_id
        }
        hash.merge!(:change => item[:change]) if item[:change]
        hash.merge!(:change_paths => item[:change_paths]) if item[:change_paths]
        hash
      end
      create_from_rows(model_handle,rows,{:convert => true})
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

    # called 'stub'  because objects refernced can change
    def self.ret_stub_display_name(object_model_name,item_display_name)
      display_name_prefix = 
        case object_model_name
         when :attribute then "setting-attribute"
         when :component then "install-component"
         when :node then "create-node"
      end
      display_name_prefix + (item_display_name ? "(#{item_display_name})" : "")
    end
  end
end
