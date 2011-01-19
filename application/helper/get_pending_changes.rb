module Ramaze::Helper
  module GetPendingChanges
    include XYZ
    def flat_list_pending_changes_in_datacenter(datacenter_id)
      last_level = pending_changes_one_level_raw(:datacenter,[datacenter_id])
      ret = Array.new
      while not last_level.empty?
        ret += last_level
        last_level = pending_changes_one_level_raw(:state_change,last_level.map{|x|x[:id]})
      end
      remove_duplicate_and_add_same_component_types(ret)
    end

    def pending_changes_to_render(datacenter_id)
      ret = pending_changes_one_level_to_render(:datacenter,[datacenter_id])
      indexed_last_level = ret.inject({}){|h,pc|h.merge(pc[:id] => pc)}
      loop do
        next_level = pending_changes_one_level_to_render(:state_change,indexed_last_level.values.map{|x|x[:id]})
        break if next_level.empty?
        next_level.each do |pc|
          parent = indexed_last_level[pc[:parent_id]]
          parent[:state_changes] ||= Array.new
          parent[:state_changes] << pc
        end
        indexed_last_level = next_level.inject({}){|h,pc|h.merge(pc[:id] => pc)}
      end
      ret
    end

    def pending_changes_one_level_to_render(parent_model_name,id_list)
      pending_changes_one_level_raw(parent_model_name,id_list).map{|pc|transform_to_render(pc)}
    end


    def pending_changes_one_level_raw(parent_model_name,id_list)
      actions = 
        pending_create_node(parent_model_name,id_list) + 
        pending_install_component(parent_model_name,id_list) +
        pending_changed_attribute(parent_model_name,id_list)
    end

    def pending_create_node(parent_model_name,id_list)
      parent_field_name = XYZ::DB.parent_field(parent_model_name,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:oneof, parent_field_name,id_list],
                    [:eq, :type,"create_node"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:created_node,parent_field_name,:state_change_id].uniq
      }
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def pending_install_component(parent_model_name,id_list)
      parent_field_name = XYZ::DB.parent_field(parent_model_name,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:oneof, parent_field_name, id_list],
                    [:eq, :type,"install-component"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:installed_component,parent_field_name,:state_change_id].uniq
      }
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def pending_changed_attribute(parent_model_name,id_list)
      parent_field_name = XYZ::DB.parent_field(parent_model_name,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:oneof, parent_field_name, id_list],
                    [:eq, :type,"setting"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:changed_attribute,parent_field_name,:state_change_id].uniq
      }      
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def remove_duplicate_and_add_same_component_types(state_changes)
      indexed_ret = Hash.new
      #remove duplicates wrt component looking at both component and component_same_type
      state_changes.each do |sc|
        if sc[:type] == "create_node"
          indexed_ret[sc[:node][:id]] = sc
        elsif ["setting","install-component"].include?(sc[:type])
          indexed_ret[sc[:component][:id]] ||= sc.reject{|k,v|[:attribute,:component_same_type].include?(k)} 
          cst = sc[:component_same_type]
          indexed_ret[cst[:id]] ||=  sc.reject{|k,v| [:attribute,:component_same_type].include?(k)}.merge(:component => cst) if cst
        else
          Log.error("unexepceted type #{sc[:type]}; ignoring")
        end
      end
      indexed_ret.values
    end


    def transform_to_render(pending_change)
      type = pending_change[:type]
      ret = [:type,:id].inject({}){|h,k|h.merge(k => pending_change[k])}
      ret.merge!(:parent_id => pending_change[:state_change_id])
      to_add = case type
        when "setting" then transform_to_render_setting(pending_change)
        when "create_node" then transform_to_render_create_node(pending_change)
        when "install-component" then transform_to_render_install_component(pending_change)
        else raise Error.new("unexpected state change type #{type}")
      end
      ret.merge(to_add)
    end

    def transform_to_render_setting(pending_change)
      attr =  pending_change[:attribute]
      cmp =  pending_change[:component]
      {:component_id => cmp[:display_name],
        :component_name => cmp[:id],
        :attribute_id => attr[:id],
        :attribute_name => attr[:display_name],
        :attribute_value => attr[:value_asserted] #TODO: need refinment on what to include fro derived value
      }
    end 

    def transform_to_render_install_component(pending_change)
      attr =  pending_change[:attribute]
      cmp =  pending_change[:component]
      { :component_name => cmp[:display_name],
        :component_id => cmp[:id]
      }
    end 

    def transform_to_render_create_node(pending_change)
      node =  pending_change[:node]
      image =  pending_change[:image]
      { :node_name => node[:display_name],
        :node_id => node[:id],
        :image_id => image[:display_name],
        :image_name => image[:id]
      }
    end 
  end
end

