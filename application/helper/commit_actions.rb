module Ramaze::Helper
  module CommitActions
    include XYZ
    def generate_workflow(pending_action_list)
      ordered_actions = OrderedActions.create(pending_action_list)
      Workflow.create(ordered_actions)
    end

    def ret_pending_installed_components(datacenter_id)
      dc_parent_field_name = ModelHandle.new(ret_session_context_id(),:action,:datacenter).parent_id_field_name()
      hash = {
        "search_pattern" => {
          :relation => :action,
          :filter => [:and,
                      [:eq, dc_parent_field_name, datacenter_id],
                      [:eq, :type,"install-component"],
                      [:eq, :state, "pending"]],
          :columns => [:id, :relative_order,:installed_component,dc_parent_field_name,:action_id]
        }
      } 
      search_object = SearchObject.create_from_input_hash(hash,:action,ret_session_context_id())
      Model.get_objects_from_search_object(search_object)
    end
  end
end
