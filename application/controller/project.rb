module XYZ
  class ProjectController < Controller
    helper :get_pending_changes
    helper :create_tasks_from_pending_changes

    def test_group_attrs(datacenter_id)
      pending_changes = flat_list_pending_changes_in_datacenter(datacenter_id.to_i)
      commit_task = create_task_from_pending_changes(pending_changes)

      augmented_attr_list = Attribute.augmented_attribute_list_from_task(commit_task)
      grouped_attrs = Attribute.ret_grouped_attributes(augmented_attr_list)
      pp grouped_attrs.map{|attr|[attr[:display_name],attr[:attr_val_type]]}
      return {:content => nil}
    end
  end
end
