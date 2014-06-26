module XYZ
  class ProjectController < AuthController
    def test_group_attrs(datacenter_id=nil)
      redirect = "/xyz/project/test_group_attrs/#{(datacenter_id||"").to_s}"
      unless datacenter_id
        datacenter_id = Model.get_objs(model_handle(:datacenter),{:cols => [:id]}).first[:id]
      end
      pending_changes = flat_list_pending_changes_in_datacenter(datacenter_id.to_i)
      commit_task = create_task_from_pending_changes(pending_changes)

      augmented_attr_list = Attribute.augmented_attribute_list_from_task(commit_task)
      
      opts = {:types_to_keep => [:unset_required]}
      grouped_attrs = Attribute.ret_grouped_attributes!(augmented_attr_list,opts)
     # pp grouped_attrs.each{|x| pp [x[:component][:display_name],x[:display_name],x[:attr_val_type]]}

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
      attr_val_hash = explicit_hash || request.params.dup
      redirect = attr_val_hash.delete("redirect")
      # convert empty strings to nils
      attr_val_hash.each{|k,v|attr_val_hash[k] = nil if v.kind_of?(String) and v.empty?}

      # TODO: if not using c_ prfix remove from view and remobe below
      attr_val_hash = attr_val_hash.inject({}) do |h,(k,v)|
        h.merge(k.gsub(/^c__[0-9]+__/,"") => v)
      end

      attribute_rows = AttributeComplexType.ravel_raw_post_hash(attr_val_hash,:attribute)
      Attribute.update_and_propagate_attributes(model_handle(:attribute),attribute_rows)
      redirect redirect
    end

    def create(explicit_hash=nil)

      params = request.params
      pp ["project_create",params]
      Project.create_new_project(model_handle,params["name"],params["type"])
      return {}
    end

    def destroy_and_delete_nodes(project_id=nil) #allowing to be nil for testing when only one project
      unless project_id
        project_id = Model.get_objs(model_handle,{:cols => [:id]}).first[:id]
      end
      create_object_from_id(project_id).destroy_and_delete_nodes()
      return {:content => {}}
    end
  end
end
