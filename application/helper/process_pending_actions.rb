module Ramaze::Helper
  module ProcessPendingActions
    include XYZ

    def add_attributes!(pending_actions)
      indexed_actions = pending_actions.inject({}){|h,a|h.merge(a[:component][:id] => a)}
      parent_field_name = DB.parent_field(:component,:attribute)
      search_pattern_hash = {
        :relation => :attribute,
        :filter => [:and,
                    [:oneof, parent_field_name, indexed_actions.keys]],
        :columns => [:id,parent_field_name,:external_ref,:attribute_value,:required]
      }
      attrs = get_objects_from_search_pattern_hash(search_pattern_hash)
      attrs.each do |attr|
        action = indexed_actions[attr[parent_field_name]]
        action[:attributes] ||= Array.new
        action[:attributes] << attr
      end
      pending_actions
    end

    def generate_workflow(pending_action_list)
      add_attributes!(pending_action_list)
      ordered_actions = OrderedActions.create(pending_action_list)
      Workflow.create(ordered_actions)
    end

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

