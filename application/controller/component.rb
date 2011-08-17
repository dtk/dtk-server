module XYZ
  class ComponentController < Controller
    helper :i18n_string_mapping

    def get(id)
      component = create_object_from_id(id)
      comp = component.get_obj_with_common_cols()
=begin
      impl = create_object_from_id(comp[:implementation_id], :implementation)
      opts = {:include_file_assets => true}
      impl_tree = impl.get_tree(opts)

      ret_obj = Hash.new
      ret_obj[:component] = comp
      ret_obj[:implementation_tree] = impl_tree
=end
#pp component.get_obj_with_common_cols()
      return {:data=>comp}
    end

    #TODO: remove when finshed testing
    def test(action,*rest)
      hash = request.params
      if action == "new_version"
        cmp_type = rest[0]
        version = rest[1] || "0.0.1"
        new_version = rest[2] ||"0.0.2"
        proj_cmp_tmpl = ret_project_component_template(cmp_type,version)
        library_obj = Model.get_objects_from_sp_hash(model_handle(:library),{:cols => [:id]}).first
        proj_cmp_tmpl.promote_template__new_version(new_version,library_obj.id_handle)
      elsif action == "update_default"
        cmp_type = rest[0]
        version = rest[1]
        attr = rest[2] 
        val = hash["val"]
        val = true if val == "true"
        val = false if val == "false"
        proj_cmp_tmpl = ret_project_component_template(cmp_type,version)
        proj_cmp_tmpl.update_default(attr,val)
      end
      return {:content => {}}
    end

    def ret_project_component_template(cmp_type,version)
      sp_hash = {
        :cols => [:id],
        :filter => [:and, 
                    [:eq,:version, version], 
                    [:eq, :component_type, cmp_type],
                    [:neq, :project_project_id, nil]]
        }
      ret = Model.get_objects_from_sp_hash(model_handle(),sp_hash).first #TODO: assume just one project
      raise Error.new("cannot find project template associated with #{cmp_type} (#{version})") unless ret
      ret
    end
   private :ret_project_component_template
    ##############################
    def edit_user
      params = request.params.reject{|k,v| v.nil? or v.empty?}
      Component.create_user_library_template(model_handle,params)
      return {:content => {}}
    end
    
    def details_old(id)
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

      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("component",component)
      tpl.assign("component_images_uri",R8::Config[:component_images_uri])

      run_javascript("R8.Displayview.init('#{id}');")

      return {:content => tpl.render()}
    end

    def details(id)
      component = get_object_by_id(id)

      tpl = R8Tpl::TemplateR8.new("component/cfg_file_list",user_context())
      tpl.set_js_tpl_name("component_cfg_file_list")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

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
=begin
      config_file_list = [
        {:id=>12345,:name=>'php.ini',:owner_id=>'1123',:owner_name=>'Rich',:created_by_id=>'12112',:created_by_name=>'Rich'},
        {:id=>12345,:name=>'http.conf',:owner_id=>'1123',:owner_name=>'Nate',:created_by_id=>'12112',:created_by_name=>'Nate'},
        {:id=>12345,:name=>'my.cnf',:owner_id=>'1123',:owner_name=>'Bob',:created_by_id=>'12112',:created_by_name=>'Bob'}
      ]
=end
      cfg_file_list = component.get_config_files();
pp '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
pp cfg_file_list

      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("component",component)
      tpl.assign("config_file_list",cfg_file_list)
      tpl.assign("component_images_uri",R8::Config[:component_images_uri])

      run_javascript("R8.Displayview.init('#{id}');")

      return {:content => tpl.render()}
#      return {:content => ""}
    end

    def add_cfg_file(id)
      tpl = R8Tpl::TemplateR8.new("component/add_cfg_file",user_context())
      tpl.assign(:component_id,id)

      return {
        :content=>tpl.render(),
        :panel=>request.params["panel_id"]
      }
    end

    def editor(id)
      component = create_object_from_id(id,:component)
      field_defs = component.get_field_def()
pp [:field_defs,field_defs]
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

    def constraints(id)
#      component = create_object_from_id(id,:component)
#      constraints = component.get_constraints()

#TODO: retool include_js to take string or hash, if hash then assumed js tpl and handled differently
      tpl = R8Tpl::TemplateR8.new("component/constraints",user_context())
#      tpl.set_js_tpl_name("component_constraints")
#      tpl_info = tpl.render()
#      include_js_tpl(tpl_info[:src])

#      include_css('component-editor')
#      include_js('fields.r8')

#     field_defs_json = JSON.generate(field_defs)
#      run_javascript("R8.Fields.init(#{field_defs_json});")

      return {
        :content=>tpl.render(),
        :panel=>request.params["panel_id"]
      }
    end

    def get_cfg_file_contents(id)
       component = get_object_by_id(id)
       return {
        :data=>component.get_config_file(request.params["file_asset_id"])
       }
    end

    def add_cfg_file_from_upload(id)
       component = get_object_by_id(id)
#      redirect_route = request.params["redirect"]
#      component_id = request.params["component_id"].to_i 

      upload_param = request.params["config_file"]
      cfg_filename = upload_param[:filename]
      tmp_file_handle = upload_param[:tempfile]
      file_content = tmp_file_handle.read 
      tmp_file_handle.close
#TODO: need to clean up ways to get at and work with objects
# create_object_from_id,get_object_by_id,id_handle(id).create_object(), etc
#      id_handle(id).create_object().add_config_file(cfg_filename,file_content)
      component.add_config_file(cfg_filename,file_content)
      #TODO: delete /tmp file File.unlink(tmp_file_path)

#     pp [:test,id_handle(component_id).create_object().get_config_file(cfg_filename)] 

=begin
pp tmp_file.path
      new_path = R8::Config[:config_file_path]+'/'+cfg_filename
      file_contents=IO.read(tmp_file.path)

      File.open(new_path, 'w') do |f|  
        f.puts file_contents
      end
=end
#      redirect redirect_route
      return {
        :data=> {
          :cfg_file_list=>component.get_config_files()
        }
      }

    end

    def upload_config()
      redirect_route = request.params["redirect"]
      component_id = request.params["component_id"].to_i 

      upload_param = request.params["config_file"]
      cfg_filename = upload_param[:filename]
      tmp_file_handle = upload_param[:tempfile]
      file_content = tmp_file_handle.read 
      tmp_file_handle.close
      id_handle(component_id).create_object().add_config_file(cfg_filename,file_content)
      #TODO: delete /tmp file File.unlink(tmp_file_path)

#     pp [:test,id_handle(component_id).create_object().get_config_file(cfg_filename)] 

=begin
pp tmp_file.path
      new_path = R8::Config[:config_file_path]+'/'+cfg_filename
      file_contents=IO.read(tmp_file.path)

      File.open(new_path, 'w') do |f|  
        f.puts file_contents
      end
=end
      redirect redirect_route
    end

    def config_templates(id)
#      component = create_object_from_id(id,:component)
#      constraints = component.get_constraints()

#TODO: retool include_js to take string or hash, if hash then assumed js tpl and handled differently
      tpl = R8Tpl::TemplateR8.new("component/upload_config_file",user_context())
      tpl.assign("component_id",id)
      tpl.assign(:_app,app_common())
#      tpl.set_js_tpl_name("component_constraints")
#      tpl_info = tpl.render()
#      include_js_tpl(tpl_info[:src])

#      include_css('component-editor')
#      include_js('fields.r8')

#     field_defs_json = JSON.generate(field_defs)
#      run_javascript("R8.Fields.init(#{field_defs_json});")

      return {
        :content=>tpl.render(),
        :panel=>request.params["panel_id"]
      }
    end

    def layout_test(id)
      #assuming that request params has field type
#      view_type = request.params["type"]||"wspace-edit" #TODO: stubbed with value wspace-edit
      view_type = request.params["type"]||"dock_display" #TODO: stubbed with value dock_display

      component = create_object_from_id(id,:component)
      field_defs = component.get_field_def()

      include_css(view_type)
      tpl = R8Tpl::TemplateR8.new("component/#{view_type}_layout",user_context())
      tpl.set_js_tpl_name("#{view_type}_layout")

      js_tpl = tpl.render()
      include_js_tpl(js_tpl[:src])

      tpl = R8Tpl::TemplateR8.new("component/#{view_type}_group_popup",user_context())
      tpl.set_js_tpl_name("#{view_type}_group_popup")
      js_tpl = tpl.render()
      include_js_tpl(js_tpl[:src])

      tpl = R8Tpl::TemplateR8.new("component/layout_editor",user_context())
      _model_var = {:i18n => get_model_i18n(model_name().to_s,user_context())}
      tpl.assign(:_component,_model_var)
      tpl.assign(:view_type,view_type)
      tpl.assign(:field_def_list,field_defs)

      view_type_list = [
        {:type=>'wspace_edit',:i18n=>'Workspace Edit',:selected=>''},
        {:type=>'dock_edit',:i18n=>'Dock Edit',:selected=>''},
        {:type=>'dock_display',:i18n=>'Dock Display',:selected=>''}
      ]
      view_type_list.each_with_index do |vt,i|
        view_type_list[i][:selected] = (view_type_list[i][:type] == view_type) ? 'selected="true"' : ''
      end

      tpl.assign(:view_type_list,view_type_list)

      include_css('layout-editor')
      include_js("#{view_type}.layout_editor.r8")

      layout_list = component.get_layouts(view_type)
#pp [:layout_list,layout_list]

      tpl.assign(:layout_list,layout_list)

      field_defs_json = JSON.generate(field_defs)
#      layout_def_json = JSON.generate(layout_list[0][:def])
      layout_json = JSON.generate(layout_list[0])
      run_javascript("R8.LayoutEditor.init(#{layout_json},#{field_defs_json});")

      return {
        :content=>tpl.render(),
        :panel=>request.params["panel_id"]
      }
    end

    def save_layout(id)
      hash = request.params
      
      layout_info = {
        :type => hash["type"]||"wspace-edit", #TODO: remove ||"wspace-edit" when value explicitly passed
        :description => hash["description"]||"sample description", #TODO: remove ||"sample description"
        :is_active =>  hash["is_active"] ? hash["is_active"] = "true" : true,
        :def => JSON.parse(hash["def"])
      }

      component = create_object_from_id(id,:component)
      component.add_layout(layout_info)
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
      attr_list_x = component.get_attributes_unraveled(to_set,:flatten_nil_value => true)
      #TODO:" temp
      attr_list = attr_list_x.map do |a|
        disabled_info = {
          :disabled_attribute => a[:is_readonly] ? "disabled" : "",
        }
        Aux::hash_subset(a,[:id,:name,:value,:i18n,:is_readonly]).merge(disabled_info)
      end

      #TODO strawman ordering; puts readonly at bottom
      ordered_attr_list = attr_list.sort do |a,b|
        if a[:disabled_attribute] == b[:disabled_attribute]
        (a[:name]||"_") <=> (b[:name]||"_")
        elsif a[:disabled_attribute].empty?
          -1
        else
          1
        end
      end

      tpl = R8Tpl::TemplateR8.new("dock/component_edit",user_context())
      tpl.assign("field_list",ordered_attr_list)
      tpl.assign("component_id",component_id)
      return {:content => tpl.render()}
    end


    def dock_display(component_id)
      component = create_object_from_id(component_id)
      to_set = {}
      attr_list = component.get_attributes_unraveled(to_set,:flatten_nil_value => true)

      #TODO The ordering should not matter all that much since the views will be generated by the view defs
      ordered_attr_list = attr_list.sort{|a,b|(a[:i18n]||"_") <=> (b[:i18n]||"_")}

      tpl = R8Tpl::TemplateR8.new("component/dock_display",user_context())
      tpl.assign("field_list",ordered_attr_list)
      tpl.assign("component_id",component_id)
      return {:content => tpl.render()}
    end

#TODO: rename to save
    def save_attributes(explicit_hash=nil)
      attr_val_hash = explicit_hash || request.params.dup
      #TODO: can thsi be handled another way
      #convert empty strings to nils
      attr_val_hash.each{|k,v|attr_val_hash[k] = nil if v.kind_of?(String) and v.empty?}
      component_id = attr_val_hash.delete("component_id").to_i
      attribute_rows = AttributeComplexType.ravel_raw_post_hash(attr_val_hash,:attribute,component_id)
      attr_mh = ModelHandle.new(ret_session_context_id(),:attribute)
      #TODO: need way to mark which ones are instance vars vs which ones are defaults
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
      #TODO: assuming parent_id is a datacenter_id
      parent_id = request.params["parent_id"]

      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())
      tpl.set_js_tpl_name("node_wspace_display")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      #compute uui positions
      assembly_left_pos = request.params["assembly_left_pos"]
    
      node_list = get_objects(:node,{:assembly_id=>id})

      dc_hash = get_object_by_id(parent_id,:datacenter)
      raise Error.new("Not implemented when parent_id is not a datacenter") if dc_hash.nil?
      #get the top most item in the list to set new positions
      top_node = {}
      top_most = 2000
    
      node_list.each do |node|
        ui = node.get_ui_info(dc_hash)
        if ui and (ui[:top].to_i < top_most.to_i)
          left_diff = assembly_left_pos.to_i - ui[:left].to_i
          top_node = {:id=>node[:id],:ui=>ui,:left_diff=>left_diff}
          top_most = ui[:top]
        end
      end

      items = Array.new
      item_id_list = Array.new
      node_list.each do |node|
        item_id_list << node[:id]
        ui = node.get_ui_info(dc_hash)
        Log.error("no coordinates for node with id #{node[:id].to_s} in #{parent_id.to_s}") unless ui
        if ui
          if node[:id] == top_node[:id]
            ui[:left] = assembly_left_pos.to_i
          else
            ui[:left] = ui[:left].to_i + top_node[:left_diff].to_i
          end
        end
        node.update_ui_info!(ui,dc_hash)
        item = {
          :type => 'node',
          :object => node,
#          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info[:template_callback],
          :ui => ui
        }
        items << item
      end

#    p_str = JSON.generate(request.params)
#    run_javascript("alert('Added assembly, here are req params:  #{p_str}');")

    addItemsObj = JSON.generate(items)
    run_javascript("R8.Workspace.addItems(#{addItemsObj});")

    item_id_list_json = JSON.generate(item_id_list)
    run_javascript("R8.Workspace.touchItems(#{item_id_list_json});")

    return {}
  end

    def add_assembly_items_ide(id=nil)
      #TODO: assuming parent_id is a datacenter_id
      parent_id = request.params["parent_id"]

      tpl = R8Tpl::TemplateR8.new("node/wspace_display_ide",user_context())
      tpl.set_js_tpl_name("node_wspace_display_ide")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      #compute uui positions
      assembly_left_pos = request.params["assembly_left_pos"]
    
      node_list = get_objects(:node,{:assembly_id=>id})

      dc_hash = get_object_by_id(parent_id,:datacenter)
      raise Error.new("Not implemented when parent_id is not a datacenter") if dc_hash.nil?
      #get the top most item in the list to set new positions
      top_node = {}
      top_most = 2000
    
      node_list.each do |node|
        ui = node.get_ui_info(dc_hash)
        if ui and (ui[:top].to_i < top_most.to_i)
          left_diff = assembly_left_pos.to_i - ui[:left].to_i
          top_node = {:id=>node[:id],:ui=>ui,:left_diff=>left_diff}
          top_most = ui[:top]
        end
      end

      items = Array.new
      item_id_list = Array.new
      node_list.each do |node|
        item_id_list << node[:id]
        ui = node.get_ui_info(dc_hash)
        Log.error("no coordinates for node with id #{node[:id].to_s} in #{parent_id.to_s}") unless ui
        if ui
          if node[:id] == top_node[:id]
            ui[:left] = assembly_left_pos.to_i
          else
            ui[:left] = ui[:left].to_i + top_node[:left_diff].to_i
          end
        end
        node.update_ui_info!(ui,dc_hash)
        item = {
          :type => 'node',
          :object => node,
#          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info[:template_callback],
          :ui => ui
        }
        items << item
      end

#    p_str = JSON.generate(request.params)
#    run_javascript("alert('Added assembly, here are req params:  #{p_str}');")

#    addItemsObj = JSON.generate(items)
#    run_javascript("R8.Workspace.addItems(#{addItemsObj});")

#    item_id_list_json = JSON.generate(item_id_list)
#    run_javascript("R8.Workspace.touchItems(#{item_id_list_json});")

    ret_obj = Hash.new
    ret_obj[:items] = items
    ret_obj[:touch_items] = item_id_list

    return {:data=>ret_obj}
  end

end
