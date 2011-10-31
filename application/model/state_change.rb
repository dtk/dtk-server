module XYZ
  class StateChange < Model

    def self.create_rerun_state_changes(node_idhs)
      sample_idh = node_idhs.first()
      sp_hash = {
        :cols => [:id,:datacenter_datacenter_id,:components]
      }
      new_item_hashes = Model.get_objects_in_set_from_sp_hash(node_idhs,sp_hash).map do |r|
        {
          :new_item => r[:component].id_handle(), 
          :parent => sample_idh.createIDH(:model_name => :datacenter, :id=> r[:datacenter_datacenter_id]),
          :type => "rerun_component"
        }
      end
      create_pending_change_items(new_item_hashes)
    end

    #TODO: deprecate
    def qualified_parent_name()
      base =  self[:base_object]
      return nil unless base
      node_or_ng = (base[:node]||{})[:display_name]||(base[:node_group]||{})[:display_name]
      component = (base[:component]||{})[:display_name]
      return nil if node_or_ng.nil? and component.nil?
      [node_or_ng,component].compact.join("/")
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
      return nil if new_item_hashes.empty? 
      parent_model_name = new_item_hashes.first[:parent][:model_name]
      model_handle = new_item_hashes.first[:parent].createMH({:model_name => :state_change, :parent_model_name => parent_model_name})
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
      display_name_prefix = 
        case object_model_name
          when :attribute then "setting-attribute"
          when :component then "install-component"
          when :node then "create_node"
      end 
      
      ref_prefix = "state_change"
      i=0
      rows = new_item_hashes.map do |item| 
        ref = "#{ref_prefix}#{(i+=1).to_s}"
        id = item[:new_item].get_id()
        parent_id = item[:parent].get_id()
        #TODO: think wil change to have display name derived on spot; problem is for example name of node changes after state change saved
        display_name = display_name_prefix + (item[:new_item][:display_name] ? "(#{item[:new_item][:display_name]})" : "")
        hash = {
          :ref => ref,
          :display_name => display_name,
          :status => "pending",
          :type => type,
          :object_type => object_model_name.to_s,
          object_id_col => id,
          parent_id_col => parent_id,
          :base_object => item[:base_object] #TODO: should deprecate
        }
        hash.merge!(:change => item[:change]) if item[:change]
        hash.merge!(:change_paths => item[:change_paths]) if item[:change_paths]
        hash
      end
      create_from_rows(model_handle,rows,{:convert => true})
    end
  end
end
