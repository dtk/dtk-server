module XYZ
  class AttributeController < Controller

    def list_under_component(component_id)
pp get_base_object_dataset_needs_to_be_set(:component).ppsql
    end
    def list_under_component(component_id)
pp get_base_object_dataset_needs_to_be_set(:component).ppsql
    end

    def list_under_node(node_id=nil)
      filter = nil
      cols = [:id,:display_name,:base_object_node,:needs_to_be_set,:attribute_value,:data_type,:semantic_type]
      field_set = Model::FieldSet.new(model_name,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => node_id.to_i) if node_id

      attribute_list = ds.all
      AttributeComplexType.flatten_attribute_list(attribute_list).each do |x|
        pp x[:qualified_attribute_name_under_node]
      end
      action_name = "list_qualified_attribute_name"
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      tpl.assign("attribute_list",attribute_list)
      return {:content => tpl.render()}
    end
   
    def deprecate_list_under_node(node_id)
#      base_ds = get_base_object_dataset_needs_to_be_set(:node)
#      ds = base_ds.where(:node__id => node_id.to_i).where_column_equal(:needs_to_be_set,true)

      filter = [:and,[:eq,:needs_to_be_set,true]] #:eq,:node__id,node_id.to_i]
      ds = get_base_object_dataset_needs_to_be_set(:node,filter).where(:param_node_id => node_id.to_i)
      attribute_list = ds.all
      action_name = "list_qualified_attribute_name"
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      tpl.assign("attribute_list",attribute_list)
      return {:content => tpl.render()}
    end
   
    def list_under_datacenter(datacenter_id=nil)
      datacenter_id = IDHandle[:c => ret_session_context_id(), :model_name => :datacenter, :uri => "/datacenter/dc1"].get_id() unless datacenter_id

#      base_ds = get_base_object_dataset_needs_to_be_set(:datacenter)
#      ds = base_ds.where(SQL::ColRef.coalesce(:parem_node_group_datacenter_id,:param_node_datacenter_id) => datacenter_id).where_column_equal(:needs_to_be_set,true)
      filter = [:and,[:eq,:needs_to_be_set,true]]
      ds = get_base_object_dataset_needs_to_be_set(:datacenter,filter).where(SQL::ColRef.coalesce(:param_node_group_datacenter_id,:param_node_datacenter_id) => datacenter_id)

      attribute_list = ds.all
      action_name = "list_qualified_attribute_name"
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
    def get_base_object_dataset_needs_to_be_set(type,filter=nil)
      field_set = Model::FieldSet.new(model_name,[:display_name,"base_object_#{type}".to_sym,:needs_to_be_set])
      SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
    end
  end
end
