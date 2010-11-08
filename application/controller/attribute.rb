module XYZ
  class AttributeController < Controller

    def list_under_component(component_id)
pp get_base_object_dataset(:component).ppsql
    end

    def list_under_node(node_id)
      base_ds = get_base_object_dataset(:node)
      ds = base_ds.where(:param_node_id => node_id.to_i).where_column_equal(:needs_to_be_set,true)
pp ds.all
      attribute_list = ds.all.map{|r|{:attribute_name => "#{r[:component][:display_name]}/#{r[:display_name]}", :id => r[:id]}}
      action_name = "list_under_node"
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      tpl.assign("attribute_list",attribute_list)
      return {:content => tpl.render()}
    end
   
    #TODO deprecate
    def list_for_component_display()
      search_object =  ret_search_object_in_request()
      raise Error.new("no search object in request") unless search_object

      model_list = Model.get_objects_from_search_object(search_object)

      #TODO: should we be using default action name
      action_name = :list
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())

      set_template_defaults_for_list!(tpl)
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("#{model_name()}_list",model_list)

      return {:content => tpl.render()}
    end
   private
    def get_base_object_dataset(type)
      @ds_cache ||= Hash.new
      return @ds_cache[type] if @ds_cache[type]
      field_set = Model::FieldSet.new(model_name,[:display_name,"base_object_#{type}".to_sym,:needs_to_be_set])
      @ds_cache[type] = SearchObject.create_from_field_set(field_set,ret_session_context_id()).create_dataset()
    end
  end
end
