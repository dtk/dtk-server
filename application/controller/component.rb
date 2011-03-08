module XYZ
  class ComponentController < Controller
    helper :i18n_string_mapping

    def details(id)
      component = get_object_by_id(id)
      tpl = R8Tpl::TemplateR8.new("component/details",user_context())

#      img_str = '<img title="' << component[:display_name] << '"' << 'src="' << R8::Config[:base_images_uri] << '/component/Icons/'<< component[:ui][:images][:tnail] << '"/>'

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(:component,user_context())
      component[:name] = _model_var[:i18n][component[:display_name].to_sym]

#TEMP UNTIL FULLY IMPLEMENTING DEPENDENCIES
      supported_os_list = [
        {:id=>12345,:name=>'Ubuntu',:version=>'10.4',:ui=>{:images=>{:icon=>'ubuntu-favicon.png'}}},
        {:id=>12345,:name=>'Debian',:version=>'6',:ui=>{:images=>{:icon=>'debian-favicon.png'}}},
        {:id=>12345,:name=>'Fedora',:version=>'14',:ui=>{:images=>{:icon=>'fedora-favicon.png'}}},
        {:id=>12345,:name=>'CentOS',:version=>'5.5',:ui=>{:images=>{:icon=>'centos-favicon.png'}}},
        {:id=>12345,:name=>'RedHat',:version=>'6',:ui=>{:images=>{:icon=>'redhat-favicon.png'}}}
      ]
      component[:supported_os_list] = supported_os_list

pp '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
pp component

      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("component",component)
      tpl.assign("component_images_uri",R8::Config[:component_images_uri])

      run_javascript("R8.Displayview.init('#{id}');")

      return {:content => tpl.render()}
    end

    def details2(id)
      component = get_object_by_id(id)
      tpl = R8Tpl::TemplateR8.new("component/details",user_context())

#      img_str = '<img title="' << component[:display_name] << '"' << 'src="' << R8::Config[:base_images_uri] << '/component/Icons/'<< component[:ui][:images][:tnail] << '"/>'

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(:component,user_context())
      component[:name] = _model_var[:i18n][component[:display_name].to_sym]

#TEMP UNTIL FULLY IMPLEMENTING DEPENDENCIES
      supported_os_list = [
        {:id=>12345,:name=>'Ubuntu',:version=>'10.4',:ui=>{:images=>{:icon=>'ubuntu-favicon.png'}}},
        {:id=>12345,:name=>'Debian',:version=>'6',:ui=>{:images=>{:icon=>'debian-favicon.png'}}},
        {:id=>12345,:name=>'Fedora',:version=>'14',:ui=>{:images=>{:icon=>'fedora-favicon.png'}}},
        {:id=>12345,:name=>'CentOS',:version=>'5.5',:ui=>{:images=>{:icon=>'centos-favicon.png'}}},
        {:id=>12345,:name=>'RedHat',:version=>'6',:ui=>{:images=>{:icon=>'redhat-favicon.png'}}}
      ]
      component[:supported_os_list] = supported_os_list

#pp '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
#pp component

      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("component",component)
      tpl.assign("component_images_uri",R8::Config[:component_images_uri])

      run_javascript("R8.Displayview.init('#{id}');")

      return {:content => tpl.render()}
#      return {:content => ""}
    end

    def editor(id)
      component = create_object_from_id(id,:component)
      field_defs = component.get_field_def()

#TODO: retool include_js to take string or hash, if hash then assumed js tpl and handled differently
      tpl = R8Tpl::TemplateR8.new("component/edit_field",user_context())
      tpl.set_js_tpl_name("component_edit_field")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("component/display_field",user_context())
      tpl.set_js_tpl_name("component_display_field")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("component/editor",user_context())
      _model_var = {:i18n => get_model_i18n(model_name().to_s,user_context())}
      tpl.assign(:_component,_model_var)

      tpl.assign(:_app,app_common())
      tpl.assign(:field_def_list,field_defs)

      include_css('component-editor')
      include_js('fields.r8')

      field_defs_json = JSON.generate(field_defs)
      run_javascript("R8.Fields.init(#{field_defs_json});")

      return {
        :content=>tpl.render(),
        :panel=>request.params["panel_id"]
      }
    end

    def save_field(id)
      field_def_json = request.params["field_def"]
      field_def_update_x = request.params.merge("field_def" => JSON.parse(field_def_json))
      #convert "" to nil
      field_def_update = field_def_update_x.inject({}) do |h,kv|
        h.merge(kv[0] => (kv[1] && kv[1].empty?) ? nil : kv[1])
      end
      field_def_update["required"] = [true,"true"].include?(field_def_update["required"])
      component = create_object_from_id(field_def_update["field_def"]["component_id"])
      new_field_def = component.update_field_def(field_def_update)
      
      run_javascript("R8.Fields.handleSavedField(#{JSON.generate(new_field_def)});")
      return {}
    end

    def instance_list(id)
      instance_list = get_objects(:component,{:ancestor_id=>id})

      tpl = R8Tpl::TemplateR8.new("component/list",user_context())
      _model_var = {:i18n => get_model_i18n(model_name().to_s,user_context())}
      tpl.assign(:_component,_model_var)
      tpl.assign(:component_list,instance_list)
      tpl.assign(:_app,app_common())

#---------------------------------
      search_context = 'component-list'
      search_content = ''
      tpl.assign(:search_content, search_content)
      tpl.assign(:search_context, search_context)

      search_object =  ret_search_object_in_request()
      tpl.assign(:list_start_prev,0)
      tpl.assign(:list_start_next,20)
      tpl.assign(:current_start,0)

      return {
        :panel=>request.params["panel_id"],
        :content=>tpl.render()
      }
    end

    def layout_test(id)
      component = create_object_from_id(id,:component)
      field_defs = component.get_field_def()

      tpl = R8Tpl::TemplateR8.new("component/layout_test",user_context())
      _model_var = {:i18n => get_model_i18n(model_name().to_s,user_context())}
      tpl.assign(:_component,_model_var)
      tpl.assign(:field_def_list,field_defs)

      include_css('layout-editor')
      include_css('wspace-modal')
      include_js('layout.editor.r8')

      layout_list = component.get_layouts(:edit)
      tpl.assign(:layout_list,layout_list)

      field_defs_json = JSON.generate(field_defs)
      layout_def_json = JSON.generate(layout_list[0][:def])
      run_javascript("R8.LayoutEditor.init(#{id},#{layout_def_json},#{field_defs_json});")

      return {
        :content=>tpl.render(),
        :panel=>request.params["panel_id"]
      }
    end

    def save_layout(id)
pp '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
pp request.params

      return {}
    end

    def publish_layout(id)
pp '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
pp request.params

      return {}
    end

##TODO ======= just for testing
=begin
    def display(id,parsed_query_string=nil)
      component = create_object_from_id(id)
      template_name = component.save_view_in_cache?(:display,user_context())
      tpl = R8Tpl::TemplateR8.new(template_name,user_context())
      vals = component.get_virtual_object_attributes()
      tpl.assign("component",vals)
      return {:content => tpl.render()}
    end
=end
    def display(id,parsed_query_string=nil)
      redirect "/xyz/component/details/#{id.to_s}"
    end

    def edit(id,parsed_query_string=nil)
      component = create_object_from_id(id)
      template_name = component.save_view_in_cache?(:edit,user_context())
      tpl = R8Tpl::TemplateR8.new(template_name,user_context())
      vals,ids = component.get_virtual_object_attributes(:ret_ids => true)
      tpl.assign("component",vals)
      tpl.assign("component_id",ids)
      return {:content => tpl.render()}
    end

    def save(explicit_hash=nil)
      attr_val_hash = explicit_hash || request.params.dup
      #TODO: can thsi be handled another way
      #convert empty strings to nils
      attr_val_hash.each{|k,v|attr_val_hash[k] = nil if v.kind_of?(String) and v.empty?}
      component_id = attr_val_hash.delete("id").to_i
      attribute_rows = AttributeComplexType.ravel_raw_post_hash(attr_val_hash,:attribute,component_id)
      attr_mh = ModelHandle.new(ret_session_context_id(),:attribute)
      Attribute.update_and_propagate_attributes(attr_mh,attribute_rows)
      redirect "/xyz/component/edit/#{component_id.to_s}"
    end

    def instance_edit_test(id,virtual_col_name=nil)
      if virtual_col_name
        id_handle = id_handle(id)
        virtual_col_def = ((DB_REL_DEF[model_name]||{})[:virtual_columns]||{})[virtual_col_name.to_sym]
        remote_col_info = (virtual_col_def||{})[:remote_dependencies]
        raise Error.new("bad virtual_col_name #{virtual_col_name}") unless remote_col_info
        dataset = SQL::DataSetSearchPattern.create_dataset_from_join_array(id_handle,remote_col_info)
        pp [:debug,dataset.all]
      end

      component = create_object_from_id(id)

      virtual_model_ref = id.to_s
      tpl = R8Tpl::TemplateR8.create("component","edit",user_context(),virtual_model_ref,:meta_db)
      vals,ids = component.get_virtual_object_attributes(:ret_ids => true)
      tpl.assign("component",vals)
      tpl.assign("component_id",ids)

      return {:content => tpl.render()}

    end
   ####### end TODO for testing 

    def dock_edit(component_id)
      component = create_object_from_id(component_id)
      to_set = {}
      attr_list = component.get_attributes_unraveled(to_set,:flatten_nil_value => true)

      #TODO The ordering should not matter all that much since the views will be generated by the view defs
      ordered_attr_list = attr_list.sort{|a,b|(a[:i18n]||"_") <=> (b[:i18n]||"_")}

      tpl = R8Tpl::TemplateR8.new("dock/component_edit",user_context())
      tpl.assign("field_list",ordered_attr_list)
      tpl.assign("component_id",component_id)
      return {:content => tpl.render()}
    end


#TODO: rename to save
    def save_attributes(explicit_hash=nil)
=begin
Would expect to have something like:

component = Compoennt.new(component_id)
component.save(request.params)
=end

      attr_val_hash = explicit_hash || request.params.dup
      #TODO: can thsi be handled another way
      #convert empty strings to nils
      attr_val_hash.each{|k,v|attr_val_hash[k] = nil if v.kind_of?(String) and v.empty?}
#pp [:in_save_attrs,attr_val_hash]
      component_id = attr_val_hash.delete("component_id").to_i
      attribute_rows = AttributeComplexType.ravel_raw_post_hash(attr_val_hash,:attribute,component_id)
      
#pp [:after_ravel,attribute_rows]

      attr_mh = ModelHandle.new(ret_session_context_id(),:attribute)
      Attribute.update_and_propagate_attributes(attr_mh,attribute_rows)
      redirect "/xyz/component/dock_edit/#{component_id.to_s}"
    end


    def testjsonlayout
      tpl = R8Tpl::TemplateR8.new('component/testjson',user_context())
      tpl.assign(:testing, 'Testing')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return {:content => tpl.render()}
    end


    def testjshello
      tpl = R8Tpl::TemplateR8.new('component/testjshello',user_context())
      tpl.set_js_tpl_name('testjshello')
      tpl.assign(:testing, 'Testing JSON Call Hello')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return tpl.render()
    end

    def testjsgoodbye
      tpl = R8Tpl::TemplateR8.new('component/testjsgoodbye',user_context())
      tpl.set_js_tpl_name('testjsgoodbye')
      tpl.assign(:testing, 'Testing JSON Call Goodbye')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return tpl.render()
    end

  end

  def add_assembly_items(id=nil)
      parent_id = request.params["parent_id"]
      assembly_left_pos = request.params["assembly_left_pos"]
=begin
      filter = [:and,[:eq,:assembly_id,id]]
      field_set = Model::FieldSet.new(:node)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      node_list = ds.all
=end
      node_list = get_objects(:node,{:assembly_id=>id})

      #get the top most item in the list to set new positions
      top_node = {}
      top_most = 2000
      node_list.each do |node|
        unless (node[:ui]||{})[parent_id.to_sym]
          Log.error("no coordinates for node with id #{node[:id].to_s} in #{parent_id.to_s}")
          return {}
        end
        if node[:ui][parent_id.to_sym][:top].to_i < top_most.to_i
          left_diff = assembly_left_pos.to_i-node[:ui][parent_id.to_sym][:left].to_i
          top_node = {:id=>node[:id],:ui=>node[:ui][parent_id.to_sym],:left_diff=>left_diff}
          top_most = node[:ui][parent_id.to_sym][:top]
        end
      end

      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())
      tpl.set_js_tpl_name("node_wspace_display")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      items = Array.new
      item_id_list = []
      node_list.each do |node|
        item_id_list << node[:id]
        if node[:id] == top_node[:id]
          node[:ui][parent_id.to_sym][:left] = assembly_left_pos
        else
          node[:ui][parent_id.to_sym][:left] = node[:ui][parent_id.to_sym][:left].to_i+top_node[:left_diff].to_i
        end

        item = {
          :type => 'node',
          :object => node,
#          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info[:template_callback],
          :ui => node[:ui][parent_id.to_sym]
        }

        items << item
      end

pp '+++++++++++++++++++++++++++++++'
pp '++++CHECKING TO SEE IF ASSEMBLY REDIRECT IS CORRECT+++'
pp '+++++++++++++++++++++++++++++++'
pp request.params
pp '+++++++++++++++++++++++++++++++'
pp items
#    p_str = JSON.generate(request.params)
#    run_javascript("alert('Added assembly, here are req params:  #{p_str}');")

    addItemsObj = JSON.generate(items)
    run_javascript("R8.Workspace.addItems(#{addItemsObj});")

    item_id_list_json = JSON.generate(item_id_list)
    run_javascript("R8.Workspace.touchItems(#{item_id_list_json});")

    return {}
  end

end
