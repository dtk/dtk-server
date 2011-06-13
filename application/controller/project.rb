module XYZ
  class ProjectController < Controller
    helper :get_pending_changes
    helper :create_tasks_from_pending_changes

    def test_group_attrs(datacenter_id)
      redirect = "/xyz/project/test_group_attrs/#{datacenter_id.to_s}"
      pending_changes = flat_list_pending_changes_in_datacenter(datacenter_id.to_i)
      commit_task = create_task_from_pending_changes(pending_changes)

      augmented_attr_list = Attribute.augmented_attribute_list_from_task(commit_task)
      
      opts = {:types_to_keep => [:unset_required]}
      grouped_attrs = Attribute.ret_grouped_attributes(augmented_attr_list,opts)
      ##pp grouped_attrs.map{|attr|[attr[:display_name],attr[:attr_val_type]]}

      i18n_mapping = get_i18n_mappings_for_models(:attribute,:component)
      attr_list = grouped_attrs.map do |a|
        name = a[:display_name]
        attr_i18n = i18n_string(i18n_mapping,:attribute,name)
        component_i18n = i18n_string(i18n_mapping,:component,a[:component][:display_name])
        node_i18n = a[:node][:display_name]
        qualified_attr_i18n = "#{node_i18n}/#{component_i18n}/#{attr_i18n}"
        {
          :id => a[:unraveled_attribute_id],
          :name =>  name,
          :value => a[:attribute_value],
          :i18n => qualified_attr_i18n
        }
      end

      tpl = R8Tpl::TemplateR8.new("project/attributes_edit",user_context())
      tpl.assign("redirect",redirect)
      tpl.assign("field_list",attr_list)
      return {:content => tpl.render()}
    end

    def save_attributes(explicit_hash=nil)
      hash = explicit_hash || request.params.dup
      redirect = hash.delete("redirect")
      pp hash
      #TODO: stub to update and propagate vars
      redirect redirect
    end
  end
end
