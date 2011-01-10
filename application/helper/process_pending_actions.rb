module Ramaze::Helper
  module ProcessPendingActions
    include XYZ

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
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

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
      ret_not_distinct = get_objects_from_search_pattern_hash(search_pattern_hash)
      indexed_ret = Hash.new
      #remove duplicates wrt component looking at both component and component_same_type
      ret_not_distinct.each do |el|
        indexed_ret[el[:component][:id]] ||= el.reject{|k,v|[:attribute,:component_same_type].include?(k)} 
        cst = el[:component_same_type]
        indexed_ret[cst[:id]] ||=  el.reject{|k,v| [:attribute,:component_same_type].include?(k)}.merge(:component => cst) if cst
      end
      indexed_ret.values
    end
  end
end

