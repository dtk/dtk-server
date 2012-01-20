#TODO: may get rid of nested state change structure because of problem such as a "parent is completed, but children arent and effeiciency; alternatively have state chanegs associated with a "container
r8_nested_require('state_change','get_pending_changes')
module XYZ
  class StateChange < Model
    extend GetPendingChangesClassMixin

    def self.update_with_current_names!(state_changes)
      #looking just for node names
      return if state_changes.empty?
      sample_sc = state_changes.first
      cols = sample_sc.keys
      return unless cols.include?(:display_name)

      filter_ids = nil 
      if cols.include?(:type) 
        filter_ids = state_changes.select{|r|r[:type] == "create_node"}.map{|r|r[:id]}
        #shortcut if cols include type and no "create_node" columns
        return if filter_ids.empty?
      end
      sp_hash = {
        :cols => [:id,:type,:created_node]
      }
      sp_hash[:filter] = [:oneof,:id,filter_ids] if filter_ids

      state_change_mh = sample_sc.model_handle
      ndx_node_name_info = get_objs(state_change_mh,sp_hash).inject({}) do |h,r|
        node_name = r[:node][:display_name]
        h.merge(r[:id] => ret_display_name(:node,node_name))
      end
      state_changes.each do |r|
        if updated_name = ndx_node_name_info[r[:id]]
          r[:display_name] = updated_name
        end
      end
    end

    def self.create_rerun_state_changes(node_idhs)
      sample_idh = node_idhs.first()
      sp_hash = {
        :cols => [:id,:datacenter_datacenter_id,:components]
      }
      new_item_hashes = Model.get_objs_in_set(node_idhs,sp_hash).map do |r|
        {
          :new_item => r[:component].id_handle(), 
          :parent => sample_idh.createIDH(:model_name => :datacenter, :id=> r[:datacenter_datacenter_id]),
          :type => "rerun_component"
        }
      end
      create_pending_change_items(new_item_hashes)
    end

    #object processing and access functions
    #######################
    def on_node_config_agent_type()
      ret = (self[:component]||{})[:config_agent_type]
      ret && ret.to_sym
    end

    def create_node_config_agent_type()
      #TODO: stub
      :ec2
    end

    def self.state_changes_are_concurrent?(state_change_list)
      rel_order = state_change_list.map{|x|x[:relative_order]}
      val = rel_order.shift
      rel_order.each{|x|return nil unless x == val}
      true
    end

    def self.create_pending_change_item(new_item_hash)
      create_pending_change_items([new_item_hash]).first
    end
    #assumption is that all parents are of same type and all changed items of same type
    def self.create_pending_change_items(new_item_hashes)
      ret = Array.new
      return ret if new_item_hashes.empty? 
      parent_model_name = new_item_hashes.first[:parent][:model_name]

      #workaround referenced in PBUILDER-161
      unless [:target,:datacenter].include?(parent_model_name)
        Log.info("workaround for PBUILDER-161: changing parent_model_name (#{parent_model_name}) to be target (datacenter)")
        parent_idh = new_item_hashes.first[:parent].get_top_container_id_handle(:datacenter)
        parent_model_name = parent_idh[:model_name]
        new_item_hashes.each{|r|r[:parent] = parent_idh}
      end

      model_handle = new_item_hashes.first[:new_item].createMH({:model_name => :state_change, :parent_model_name => parent_model_name})
      object_model_name = new_item_hashes.first[:new_item][:model_name]
      object_id_col = "#{object_model_name}_id".to_sym
      parent_id_col = model_handle.parent_id_field_name()
      type = new_item_hashes.first[:type] ||  
        case object_model_name
          when :attribute then "setting"
          when :component then "install_component"
          when :node then "create_node"
          else raise ErrorNotImplemented.new("when object type is #{object_model_name}")
      end 
      
      ref_prefix = "state_change"
      i=0
      rows = new_item_hashes.map do |item| 
        ref = "#{ref_prefix}#{(i+=1).to_s}"
        id = item[:new_item].get_id()
        parent_id = item[:parent].get_id()
        #TODO: think wil change to have display name derived on spot; problem is for example name of node changes after state change saved
        display_name = ret_display_name(object_model_name,item[:new_item][:display_name])
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

    def self.ret_display_name(object_model_name,item_display_name)
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
