module Ramaze::Helper
  module ProcessPendingActions
    include XYZ

    def pending_install_component(datacenter_id)
      parent_field_name = XYZ::DB.parent_field(:datacenter,:action)
      search_pattern_hash = {
        :relation => :action,
        :filter => [:and,
                    [:eq, parent_field_name, datacenter_id],
                    [:eq, :type,"install-component"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:installed_component,parent_field_name,:action_id]
      }
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def pending_create_node(datacenter_id)
      parent_field_name = XYZ::DB.parent_field(:datacenter,:action)
      search_pattern_hash = {
        :relation => :action,
        :filter => [:and,
                    [:eq, parent_field_name, datacenter_id],
                    [:eq, :type,"create_node"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:created_node,parent_field_name,:action_id]
      }
      get_objects_from_search_pattern_hash(search_pattern_hash)
    end

    def pending_changed_attribute(datacenter_id)
      parent_field_name = XYZ::DB.parent_field(:datacenter,:action)
      search_pattern_hash = {
        :relation => :action,
        :filter => [:and,
                    [:eq, parent_field_name, datacenter_id],
                    [:eq, :type,"setting"],
                    [:eq, :state, "pending"]],
        :columns => [:id, :relative_order,:type,:changed_attribute,parent_field_name,:action_id]
      }
      ret_not_distinct = get_objects_from_search_pattern_hash(search_pattern_hash)
      indexed_ret = Hash.new
      #remove duplicates wrt component
      ret_not_distinct.each do |el|
        indexed_ret[el[:component][:id]] ||= el.reject{|k,v|k == :attribute} 
      end
      indexed_ret.values
    end
  end
end

