module XYZ
  class ProjectController < Controller
    helper :get_pending_changes
    helper :create_tasks_from_pending_changes

    def test_group_attrs(datacenter_id)
      pending_changes = flat_list_pending_changes_in_datacenter(datacenter_id.to_i)
      commit_task = create_task_from_pending_changes(pending_changes)

      augmented_attr_list = Attribute.augmented_attribute_list_from_task(commit_task)
      grouped_attrs = Attribute.ret_grouped_attributes(augmented_attr_list)
      ##pp grouped_attrs.map{|attr|[attr[:display_name],attr[:attr_val_type]]}

      i18n = get_i18n_mappings_for_models(:attribute)
      attr_list = grouped_attrs.map do |a|
        name = a[:display_name]
        {
          :id => a[:unraveled_attribute_id],
          :name =>  name,
          :value => a[:attribute_value],
          :i18n => i18n_string(i18n,:attribute,name),
        }
      end

      redirect = "/xyz/project/test_group_attrs/#{datacenter_id.to_s}"
      tpl = R8Tpl::TemplateR8.new("project/attributes_edit",user_context())
      tpl.assign("redirect",redirect)
      tpl.assign("field_list",attr_list)
      return {:content => tpl.render()}
    end

    def save_attributes(explicit_hash=nil)
      hash = explicit_hash || request.params.dup
      redirect = hash.delete("redirect")
      pp hash
      redirect redirect
    end
  end
end
