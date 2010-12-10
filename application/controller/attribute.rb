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
      cols = [:id,:display_name,:base_object_node,:needs_to_be_set,:value_actual,:value_derived,:data_type,:semantic_type]
      field_set = Model::FieldSet.new(model_name,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => node_id.to_i) if node_id

      raw_attribute_list = ds.all
      attribute_list = AttributeComplexType.flatten_attribute_list(raw_attribute_list)

      cols = [:id,:display_name,:base_object_node_feature,:needs_to_be_set,:value_actual,:value_derived,:data_type,:semantic_type]
      field_set = Model::FieldSet.new(model_name,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => node_id.to_i) if node_id
      #TODO: also filter out when component is not feature
#pp ds.all
      

      action_name = "list_qualified_attribute_name_under_node"
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      tpl.assign("attribute_list",attribute_list)
      return {:content => tpl.render()}
    end

    def ports_under_node(node_id=nil)
      filter = [:and,[:eq,:is_port,true],[:eq,:port_is_external,true]]
      cols = [:id,:display_name,:base_object_node,:value_derived,:value_asserted]
      field_set = Model::FieldSet.new(model_name,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => node_id.to_i) if node_id
      port_list = ds.all
      port_list.each do |el|
        val = el[:attribute_value]
        el[:value] = (val.kind_of?(Hash) or val.kind_of?(Array)) ? JSON.generate(val) : val
      end
      action_name = "list_ports_under_node"
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      tpl.assign("port_list",port_list)
      return {:content => tpl.render()}
    end

    def edit_under_node(node_id=nil)
      filter = nil
      cols = [:id,:display_name,:base_object_node,:needs_to_be_set,:value_actual,:value_derived,:data_type,:semantic_type]
      field_set = Model::FieldSet.new(model_name,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => node_id.to_i) if node_id

      raw_attribute_list = ds.all
      attribute_list = AttributeComplexType.flatten_attribute_list(raw_attribute_list)
      #add name and attr_id from :qualified_attribute_name_under_node and :qualified_attribute_id_under_node
      attribute_list.each do |el|
        el[:attr_id] = el[:qualified_attribute_id_under_node]
        el[:name] = el[:qualified_attribute_name_under_node]
      end
      #order attribute list :qualified_attribute_name_under_node 
      ordered_attr_list = attribute_list.sort{|a,b|a[:name] <=> b[:name]}

      action_name = "test_node_level_edit"
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      tpl.assign("id",node_id.to_s) if node_id
      tpl.assign("attribute_list",ordered_attr_list)
      return {:content => tpl.render()}
    end

    
    def list_under_datacenter(datacenter_id=nil)
      datacenter_id = IDHandle[:c => ret_session_context_id(), :model_name => :datacenter, :uri => "/datacenter/dc1"].get_id() unless datacenter_id
      filter = nil
      cols = [:id,:display_name,:base_object_datacenter,:needs_to_be_set,:value_actual,:value_derived,:data_type,:semantic_type]
      field_set = Model::FieldSet.new(model_name,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(SQL::ColRef.coalesce(:param_node_group_datacenter_id,:param_node_datacenter_id) => datacenter_id)

      raw_attribute_list = ds.all
      attribute_list = AttributeComplexType.flatten_attribute_list(raw_attribute_list)

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

    def wspace_node_display(node_id=nil)
=begin
pp ')))))))))))))))))))))))))))))'
pp request
pp ')))))))))))))))))))))))))))))'
=end
      filter = nil
      cols = [:id,:display_name,:base_object_node,:needs_to_be_set,:value_actual,:value_derived,:data_type,:semantic_type]
      field_set = Model::FieldSet.new(model_name,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => node_id.to_i) if node_id
      raw_attribute_list = ds.all
      attribute_list = AttributeComplexType.flatten_attribute_list(raw_attribute_list)
      #add name and attr_id from :qualified_attribute_name_under_node and :qualified_attribute_id_under_node

      attribute_list.each do |el|
        name = el[:qualified_attribute_name_under_node].gsub('][',' ')
        name = name.gsub('[',' ')
        name = name.gsub(']',' ')
        name_parts = name.split(' ')
        el[:display_name] = name_parts[(name_parts.length-1)]
        el[:value] = el[:attribute_value]
      end
      #order attribute list :qualified_attribute_name_under_node 
      ordered_attr_list = attribute_list.sort{|a,b|a[:display_name] <=> b[:display_name]}

#      tpl = R8Tpl::TemplateR8.new("#{model_name}/wspace_node_display",user_context())
      tpl = R8Tpl::TemplateR8.new("attribute/wspace_node_display",user_context())
      tpl.assign(:model_name,model_name)
      tpl.assign(:node_id,node_id)
      tpl.assign(:_app,app_common())
      tpl.assign(:attribute_list,ordered_attr_list)
      return {
        :content => tpl.render(),
        :panel => 'wspace-dock-body'
      }
    end

    def wspace_node_edit(node_id=nil)
      filter = nil
      cols = [:id,:display_name,:base_object_node,:needs_to_be_set,:value_actual,:value_derived,:data_type,:semantic_type]
      field_set = Model::FieldSet.new(model_name,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => node_id.to_i) if node_id

      raw_attribute_list = ds.all
      attribute_list = AttributeComplexType.flatten_attribute_list(raw_attribute_list)
      #add name and attr_id from :qualified_attribute_name_under_node and :qualified_attribute_id_under_node

      attribute_list.each do |el|
        name = el[:qualified_attribute_name_under_node].gsub('][',' ')
        name = name.gsub('[',' ')
        name = name.gsub(']',' ')
        name_parts = name.split(' ')
        el[:display_name] = name_parts[(name_parts.length-1)]
        el[:value] = el[:attribute_value]
      end
      #order attribute list :qualified_attribute_name_under_node 
      ordered_attr_list = attribute_list.sort{|a,b|a[:display_name] <=> b[:display_name]}

#      tpl = R8Tpl::TemplateR8.new("#{model_name}/wspace_node_edit",user_context())
      tpl = R8Tpl::TemplateR8.new("attribute/wspace_node_edit",user_context())
      tpl.assign(:model_name,model_name)
      tpl.assign(:node_id,node_id)
      tpl.assign(:_app,app_common())
      tpl.assign(:attribute_list,ordered_attr_list)
      return {
        :content => tpl.render(),
        :panel => 'wspace-dock-body'
      }
    end

   private
    def get_base_object_dataset_needs_to_be_set(type,filter=nil)
      field_set = Model::FieldSet.new(model_name,[:display_name,"base_object_#{type}".to_sym,:needs_to_be_set])
      SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
    end
  end
end
