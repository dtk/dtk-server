module XYZ
  class AttributeController < AuthController
    def get_datatypes()
      datatypes = AttributeDatatype.ret_datatypes()
      {:data => datatypes}
    end

    def get(attribute_id)
      attr_def =  create_object_from_id(attribute_id).get_attribute_def()
      {:data => attr_def}
    end

    # Haris & Amar: Sets attribute value by attribute ID - Currently used for setting module component attribute default value
    def rest__set()
      attribute_id, attribute_value = ret_non_null_request_params(:attribute_id, :attribute_value)
      Attribute.get_attribute_from_identifier(attribute_id,model_handle())
      attribute_instance = id_handle(attribute_id,:attribute).create_object(:model_name => :attribute)
      attribute_instance.set_attribute_value(attribute_value)
      
      rest_ok_response( :attribute_id => attribute_id )
    end

    #TODO: cleanup so dont have as much duplication with what is on init; wrote here becse not all cols for attribute save/update are actual columns
    #update or create depending on whether id is in post content
    def save(explicit_hash=nil,opts={})
      hash = explicit_hash || request.params.dup
      ### special fields
      id = hash.delete("id")
      id = nil if id.kind_of?(String) and id.empty?
      parent_id = hash.delete("parent_id")
      parent_model_name = hash.delete("parent_model_name")
      model_name = hash.delete("model")
      name = hash.delete("name") || hash["display_name"]
      redirect = (not (hash.delete("redirect").to_s == "false"))

      #TODO: revisit during cleanup, return_model used for creating links
      rm_val = hash.delete("return_model")
      return_model = rm_val && rm_val == "true"
      
      if id 
        #update
        update_from_hash(id.to_i,hash)
      else
        #create
        #TODO: cleanup confusion over hash and string leys
        hash.merge!({:display_name => name}) unless (hash.has_key?(:display_name) or hash.has_key?("display_name"))
        parent_id_handle = nil
        create_hash = nil
        if parent_id
          parent_id_handle = id_handle(parent_id,parent_model_name)
          create_hash = {model_name.to_sym => {name => hash}}
        else
          parent_id_handle = top_level_factory_id_handle()
          create_hash = {name.to_sym => hash}
        end
        new_id = create_from_hash(parent_id_handle,create_hash)
        id = new_id if new_id
      end

      if return_model
        return {:data=> get_object_by_id(id)}
      end
    
      return id if opts[:return_id]
      redirect "/xyz/#{model_name()}/display/#{id.to_s}" if redirect
    end

    def list_under_node(node_id=nil)
      filter = nil
      cols = [:id,:display_name,:value_actual,:value_derived,:data_type,:semantic_type]
      field_set = Model::FieldSet.new(model_name,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => node_id.to_i) if node_id

      raw_attribute_list = ds.all
      attribute_list = AttributeComplexType.flatten_attribute_list(raw_attribute_list)

      cols = [:id,:display_name,:value_actual,:value_derived,:data_type,:semantic_type]
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
      cols = [:id,:display_name,:value_derived,:value_asserted]
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
      cols = [:id,:display_name,:value_actual,:value_derived,:data_type,:semantic_type]
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
      cols = [:id,:display_name,:value_actual,:value_derived,:data_type,:semantic_type]
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
      cols = [:id,:display_name,:value_actual,:value_derived,:data_type,:semantic_type]
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
      cols = [:id,:display_name,:value_actual,:value_derived,:data_type,:semantic_type]
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
  end
end
