module Ramaze::Helper
  module CommitActions
    include XYZ
    def generate_workflow(pending_action_list)
      add_attributes!(pending_action_list)
      ordered_actions = OrderedActions.create(pending_action_list)
      Workflow.create(ordered_actions)
    end

    def ret_pending_installed_components(datacenter_id)
      parent_field_name = DB.parent_field_name(:datacenter,:action)
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

    def add_attributes!(pending_action_list)
    end
  end
end
