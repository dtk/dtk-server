module Ramaze::Helper
  module ProcessPendingActions
    include XYZ

    def pending_create_node(datacenter_id)
      parent_field_name = XYZ::DB.parent_field(:datacenter,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:eq, parent_field_name, datacenter_id],
                    [:eq, :type,"create_node"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:created_node,parent_field_name,:state_change_id]
      }
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def pending_install_component(datacenter_id)
      parent_field_name = XYZ::DB.parent_field(:datacenter,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:eq, parent_field_name, datacenter_id],
                    [:eq, :type,"install-component"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:installed_component,parent_field_name,:state_change_id]
      }
      actions = get_objects_from_search_pattern_hash(search_pattern_hash)
      remove_duplicate_and_add_same_component_types(actions)
    end

    def pending_changed_attribute(datacenter_id)
      parent_field_name = XYZ::DB.parent_field(:datacenter,:state_change)
      search_pattern_hash = {
        :relation => :state_change,
        :filter => [:and,
                    [:eq, parent_field_name, datacenter_id],
                    [:eq, :type,"setting"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:changed_attribute,parent_field_name,:state_change_id]
      }      
      actions = get_objects_from_search_pattern_hash(search_pattern_hash)
      remove_duplicate_and_add_same_component_types(actions)
    end

    def remove_duplicate_and_add_same_component_types(actions)
      indexed_ret = Hash.new
      #remove duplicates wrt component looking at both component and component_same_type
      actions.each do |a|
        indexed_ret[a[:component][:id]] ||= a.reject{|k,v|[:attribute,:component_same_type].include?(k)} 
        cst = a[:component_same_type]
        indexed_ret[cst[:id]] ||=  a.reject{|k,v| [:attribute,:component_same_type].include?(k)}.merge(:component => cst) if cst
      end
      indexed_ret.values
    end
  end
end

