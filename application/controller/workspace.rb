module XYZ
  class WorkspaceController < Controller
#TODO: move to viewspace controller
    def update_pos(id)
      items_to_save = JSON.parse(request.params["item_list"])
      items_to_save.each do |item|
        item_id = item[0]
        model_name = item[1]["model"].to_sym

        item_obj = get_object_by_id(item[0],model_name)
#DEBUG
p '==================================================='
pp [:before_change,item_obj[:ui]]
        id_index = id.to_s.to_sym #TODO: need to reaxamine fn insider update from hash that symbolizes all keys and nested keys
        item_obj[:ui][id_index] = {:left => item[1]["pos"][0], :top => item[1]["pos"][1]}
p '==================================================='
pp [:after_change, item_obj[:ui]]
        update_from_hash(item_id.to_i,item_obj,model_name)


=begin
        new_pos_update = {:ui => {id => {:left => item[1]["pos"][0], :top => item[1]["pos"][1]}}}
        update_from_hash(item_id.to_i,new_pos_update,model_name, :partial_value=>true)
        pp [:debug_stored_new_pos, get_object_by_id(item[0],model_name)[:ui]]
=end
      end
      return {}
    end


    def index
#TODO: make call to load the users/system already in use plugins,cmds,etc
      include_js('plugins/search.cmdhandler')
#TODO: remove this after fully getting viewspaces going
      add_js_exe("R8.Workspace.setupNewItems();")
#      add_js_exe("R8.Toolbar.init({node:'group-01',tools:['quicksearch']});")
      return {
        :content=>'',
        :panel=>'viewspace'
      }
    end

    def loaddatacenter(id,parsed_query_string=nil)
#TODO: make call to load the users/system already in use plugins,cmds,etc
      include_js('plugins/search.cmdhandler')

=begin
#TODO: make this generic to load all items for a viewspace, not just loaddatacenter
      #retrieve the nodes
      node_list = get_objects(node_name.to_sym,where_clause)

      tpl = R8Tpl::TemplateR8.new("node/wspace_list",user_context())
      tpl.set_js_tpl_name("node_wspace_list")
      tpl.assign('node_list',node_list)
=end
      return {:content=>''}
    end

    #This function will be called after the workspace framework is loaded,
    #probably as part of an action set
    def loadtoolbar
=begin
      toolbar_items = workspace.get_toolbar_items
      layout :workspace__toolbar_items
      assign(@toolbar_items,toolbar_items)
      render 'toolbar_items'

      #build in roles/permission checks here to filter the list
=end
    end

    def search
#pp request.params
      model_name = request.params['model_name']
      field_set = Model::FieldSet.default(model_name.to_sym)
#      search_query = request.params['sq']

      where_clause = {}
      request.params.each do |name,value|
        (field_set.include_col?(name.to_sym)) ? where_clause[name.to_sym] = value : nil;
      end

#      where_clause = {:display_name => search_query}
      if where_clause
        where_clause = where_clause.inject(nil){|h,o|SQL.and(h,SQL::WhereCondition.like(o[0],"#{o[1]}%"))}
      end
      
      #restrict results to belong to library
      where_clause = SQL.and(where_clause,SQL.not(:library_library_id => nil))

      model_list = get_objects(model_name.to_sym,where_clause)
      model_list.each_with_index do |model,index|
        model_list[index][:model_name] = model_name
          body_value = ''
          model_list[index][:ui].nil? ? model_list[index][:ui] = {} : nil
          model_list[index][:ui][:images].nil? ? model_list[index][:ui][:images] = {} : nil

         !model_list[index][:ui][:images][:tnail].nil? ? img_value = '<div class="img_wrapper"><img title="' << model_list[index][:display_name] << '"' << 'src="' << R8::Config[:base_images_uri] << '/' << model_name << 'Icons/'<< model_list[index][:ui][:images][:tnail] <<'"/></div>' : img_value = ""
          body_value = img_value
          
          body_value == '' ? body_value = model_list[index][:display_name] : nil
          model_list[index][:body_value] = body_value
      end

      tpl = R8Tpl::TemplateR8.new("workspace/wspace_search_#{model_name}",user_context())
      tpl.set_js_tpl_name("wspace_search_#{model_name}")
      tpl.assign('model_list',model_list)

      slide_width = 170*model_list.size
      tpl.assign('slide_width',slide_width)
      #TODO: needed to below back in so template did not barf
 # }
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("model_name",model_name)

      tpl_result = tpl.render()
      tpl_result[:panel] = model_name+'-search-list-container'
      return tpl_result
    end

    #TODO: datacenter_id=nil is stub
    def list_items(datacenter_id=nil)

      if datacenter_id.nil?
        datacenter_id = IDHandle[:c => ret_session_context_id(), :uri => "/datacenter/dc1", :model_name => :datacenter].get_id()
      end

      model_name = :node_group      
      filter_params = {:parent_id => datacenter_id}
      search_object =  ret_node_group_search_object(filter_params)

      model_list = Model.get_objects_from_search_object(search_object)
pp model_list

#TODO: deprecate add_js_exe for run_javascript
      add_js_exe("R8.Workspace.setupNewItems();")
      top = 100
      left = 100
      model_list.each_with_index do |node_group,index|
        model_list[index][:model_name] = model_name
        model_list[index][:ui].nil? ? model_list[index][:ui] = {} : nil
        model_list[index][:ui][:top].nil? ? model_list[index][:ui][:top] = top : nil
        model_list[index][:ui][:left].nil? ? model_list[index][:ui][:left] = left : nil
        top = top+100
        left = left+100

#        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[index][:id]}',tools:['quicksearch']});")
      end
        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[0][:id]}',tools:['quicksearch']});")

      tpl = R8Tpl::TemplateR8.new("node_group/wspace_list",user_context())
#      tpl.set_js_tpl_name("wspace_list_ng_#{model_name}")
      tpl.assign('node_group_list',model_list)

#TODO: temp
      tpl.assign('datacenter_name','dc1')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("model_name",model_name)
      tpl.assign("num_nodes",10) #TODO stub
#      tpl_result = tpl.render()
#      tpl_result[:panel] = 'viewspace'
#      return tpl_result
      return {
        :content => tpl.render(),
        :panel => 'viewspace'
      }
    end

    #TODO: datacenter_id=nil is stub
    def list_items_new(datacenter_id=nil)
      if datacenter_id.nil?
        datacenter_id = IDHandle[:c => ret_session_context_id(), :uri => "/datacenter/dc1", :model_name => :datacenter].get_id()
      end

      datacenter = get_object_by_id(datacenter_id,:datacenter)
pp datacenter
      view_space = Hash.new
      view_space = {
        :type => 'datacenter',
        :object => datacenter
      }
      v_space_obj = JSON.generate(view_space)
      run_javascript("R8.Workspace.pushViewSpace(#{v_space_obj});")

      model_name = :node_group      
      filter_params = {:parent_id => datacenter_id}
      search_object =  ret_node_group_search_object(filter_params)

      model_list = Model.get_objects_from_search_object(search_object)
#pp model_list

      top = 100
      left = 100
      #--------Setup Toolbar for access each group from ACL's---------
#        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[0][:id]}',tools:['quicksearch']});")
      user_has_toolbar_access = true
      user_group_tool_list = Array.new
      user_group_tool_list << 'quicksearch'
      toolbar_def = {
        :tools => user_group_tool_list
      }

#TODO: place holder stubs for ideas on possible future behavior
#      UI::workspace.add_item(model_list[i])
#      UI::workspace.render()
      tpl = R8Tpl::TemplateR8.new("node_group/wspace_list",user_context())
      tpl.set_js_tpl_name("wspace_list_ng_#{model_name}")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

=begin
{:template_vars=>{},
 :src=>"wspace_list_ng_node_group.js",
 :template_callback=>"wspace_list_ng_node_group"}
=end

      model_list.each_with_index do |node_group,index|
        model_list[index][:model_name] = model_name
        model_list[index][:ui].nil? ? model_list[index][:ui] = {} : nil
        model_list[index][:ui][:top].nil? ? model_list[index][:ui][:top] = top : nil
        model_list[index][:ui][:left].nil? ? model_list[index][:ui][:left] = left : nil
        top = top+100
        left = left+100

        #--------Setup Item In Workspace---------
#        item_def = JSON.generate(model_list[index])
#        add_js_exe("R8.Workspace.setupItem({type:'node_group',item:#{item_def},'toolbar_def':#{toolbar_def}});")
        #----------------------------------------

#        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[index][:id]}',tools:['quicksearch']});")
      end

#TODO: decide if its possible in clean manner to manage toolbar access at item level in ad-hoc ways
#right now single toolbar def for all items in list for each type
      #--------Add Node Group List to Workspace-----
      items = Hash.new
      items = {
        :type => 'node_group',
        :items => model_list,
        :toobar_def => toolbar_def,
        :tpl_callback => tpl_info[:template_callback]
      }
      addItemsObj = JSON.generate(items)
      run_javascript("R8.Workspace.addItems(#{addItemsObj});")
      #---------------------------------------------

#        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[0][:id]}',tools:['quicksearch']});")

=begin
      tpl.assign('node_group_list',model_list)

#TODO: temp
      tpl.assign('datacenter_name','dc1')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("model_name",model_name)
      tpl.assign("num_nodes",10) #TODO stub
#      tpl_result = tpl.render()
#      tpl_result[:panel] = 'viewspace'
#      return tpl_result
=end
      return {
        :content => '',
        :panel => 'viewspace'
      }
=begin
      return {
        :content => tpl.render(),
        :panel => 'viewspace'
      }
=end
    end

    #TODO: datacenter_id=nil is stub
    def list_items_new(datacenter_id=nil)
      if datacenter_id.nil?
        datacenter_id = IDHandle[:c => ret_session_context_id(), :uri => "/datacenter/dc1", :model_name => :datacenter].get_id()
      end

      datacenter = get_object_by_id(datacenter_id,:datacenter)
pp datacenter
      view_space = Hash.new
      view_space = {
        :type => 'datacenter',
        :object => datacenter
      }
      v_space_obj = JSON.generate(view_space)
      run_javascript("R8.Workspace.pushViewSpace(#{v_space_obj});")

      model_name = :node_group      
      filter_params = {:parent_id => datacenter_id}
      search_object =  ret_node_group_search_object(filter_params)

      model_list = Model.get_objects_from_search_object(search_object)
#pp model_list

      top = 100
      left = 100
      #--------Setup Toolbar for access each group from ACL's---------
#        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[0][:id]}',tools:['quicksearch']});")
      user_has_toolbar_access = true
      user_group_tool_list = Array.new
      user_group_tool_list << 'quicksearch'
      toolbar_def = {
        :tools => user_group_tool_list
      }

#TODO: place holder stubs for ideas on possible future behavior
#      UI::workspace.add_item(model_list[i])
#      UI::workspace.render()
      tpl = R8Tpl::TemplateR8.new("node_group/wspace_list",user_context())
      tpl.set_js_tpl_name("wspace_list_ng_#{model_name}")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

=begin
{:template_vars=>{},
 :src=>"wspace_list_ng_node_group.js",
 :template_callback=>"wspace_list_ng_node_group"}
=end

      model_list.each_with_index do |node_group,index|
        model_list[index][:model_name] = model_name
        model_list[index][:ui].nil? ? model_list[index][:ui] = {} : nil
        model_list[index][:ui][:top].nil? ? model_list[index][:ui][:top] = top : nil
        model_list[index][:ui][:left].nil? ? model_list[index][:ui][:left] = left : nil
        top = top+100
        left = left+100

        #--------Setup Item In Workspace---------
#        item_def = JSON.generate(model_list[index])
#        add_js_exe("R8.Workspace.setupItem({type:'node_group',item:#{item_def},'toolbar_def':#{toolbar_def}});")
        #----------------------------------------

#        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[index][:id]}',tools:['quicksearch']});")
      end

#TODO: decide if its possible in clean manner to manage toolbar access at item level in ad-hoc ways
#right now single toolbar def for all items in list for each type
      #--------Add Node Group List to Workspace-----
      items = Hash.new
      items = {
        :type => 'node_group',
        :items => model_list,
        :toobar_def => toolbar_def,
        :tpl_callback => tpl_info[:template_callback]
      }
      addItemsObj = JSON.generate(items)
      run_javascript("R8.Workspace.addItems(#{addItemsObj});")
      #---------------------------------------------

#        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[0][:id]}',tools:['quicksearch']});")

=begin
      tpl.assign('node_group_list',model_list)

#TODO: temp
      tpl.assign('datacenter_name','dc1')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("model_name",model_name)
      tpl.assign("num_nodes",10) #TODO stub
#      tpl_result = tpl.render()
#      tpl_result[:panel] = 'viewspace'
#      return tpl_result
=end
      return {
        :content => '',
        :panel => 'viewspace'
      }
=begin
      return {
        :content => tpl.render(),
        :panel => 'viewspace'
      }
=end
    end

    #TODO: datacenter_id=nil is stub
    def list_items_2(datacenter_id=nil)
      include_js('plugins/search.cmdhandler')

      if datacenter_id.nil?
        datacenter_id = IDHandle[:c => ret_session_context_id(), :uri => "/datacenter/dc1", :model_name => :datacenter].get_id()
      end

      datacenter = get_object_by_id(datacenter_id,:datacenter)

      view_space = Hash.new
      view_space = {
        :type => 'datacenter',
        :object => datacenter
      }
      v_space_obj = JSON.generate(view_space)
      run_javascript("R8.Workspace.pushViewSpace(#{v_space_obj});")

      model_name = :node_group
      filter_params = {:parent_id => datacenter_id}
      search_object =  ret_node_group_search_object(filter_params)

      model_list = Model.get_objects_from_search_object(search_object)
#pp model_list

      #--------Setup Toolbar for access each group from ACL's---------
#        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[0][:id]}',tools:['quicksearch']});")
      user_has_toolbar_access = true
      user_group_tool_list = Array.new
      user_group_tool_list << 'quicksearch'
      toolbar_def = {
        :tools => user_group_tool_list
      }
      include_js('toolbar.quicksearch.r8')

#TODO: place holder stubs for ideas on possible future behavior
#      UI::workspace.add_item(model_list[i])
#      UI::workspace.render()

      tpl = R8Tpl::TemplateR8.new("node_group/wspace_display",user_context())
      tpl.set_js_tpl_name("ng_wspace_display")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

=begin
{:template_vars=>{},
 :src=>"wspace_list_ng_node_group.js",
 :template_callback=>"wspace_list_ng_node_group"}
=end

      #--------Add Node Group List to Workspace-----
      items = Array.new
      top = 100
      left = 100

      model_list.each_with_index do |node_group,index|
        model_list[index][:model_name] = model_name
        model_list[index][:ui].nil? ? model_list[index][:ui] = {} : nil
        model_list[index][:ui][:top].nil? ? model_list[index][:ui][:top] = top : nil
        model_list[index][:ui][:left].nil? ? model_list[index][:ui][:left] = left : nil
        top = top+100
        left = left+100

        item = {
          :type => model_name,
          :object => model_list[index],
          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info[:template_callback]
        }
        items << item
      end

      #----------------------------------------------------
      #-------Grab nodes in the datacenter-----------------
      #----------------------------------------------------
      #need to augment for nodes that are in datacenter directly and not node groups
      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())
      tpl.set_js_tpl_name("node_wspace_display")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      model_name = :node
      field_set = Model::FieldSet.default(model_name)
      node_list = get_objects(model_name,{:datacenter_datacenter_id=>datacenter_id,:ds_source_obj_type=>'image'})

      node_list.each do |node|
#DEBUG
p '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
pp node
        item = {
          :type => model_name.to_s,
          :object => node,
          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info[:template_callback]
        }
        items << item
      end
      #----------------------------------------------------
      #----------------------------------------------------
      #----------------------------------------------------

#TODO: decide if its possible in clean manner to manage toolbar access at item level in ad-hoc ways
#right now single toolbar def for all items in list for each type

      addItemsObj = JSON.generate(items)
      run_javascript("R8.Workspace.addItems(#{addItemsObj});")

      #---------------------------------------------

      return {
        :content => '',
        :panel => 'viewspace'
      }
    end

    def search_2
#pp request.params
      model_name = request.params['model_name']
      field_set = Model::FieldSet.default(model_name.to_sym)
#      search_query = request.params['sq']

      where_clause = {}
      request.params.each do |name,value|
        (field_set.include_col?(name.to_sym)) ? where_clause[name.to_sym] = value : nil;
      end

#      where_clause = {:display_name => search_query}
      if where_clause
        where_clause = where_clause.inject(nil){|h,o|SQL.and(h,SQL::WhereCondition.like(o[0],"#{o[1]}%"))}
      end
 
      model_list = get_objects(model_name.to_sym,where_clause)
      model_list.each_with_index do |model,index|
        model_list[index][:model_name] = model_name
          body_value = ''
          model_list[index][:ui].nil? ? model_list[index][:ui] = {} : nil
          model_list[index][:ui][:images].nil? ? model_list[index][:ui][:images] = {} : nil

         !model_list[index][:ui][:images][:tnail].nil? ? img_value = '<div class="img_wrapper"><img title="' << model_list[index][:display_name] << '"' << 'src="' << R8::Config[:base_images_uri] << '/' << model_name << 'Icons/'<< model_list[index][:ui][:images][:tnail] <<'"/></div>' : img_value = ""
          body_value = img_value
          
          body_value == '' ? body_value = model_list[index][:display_name] : nil
          model_list[index][:body_value] = body_value
      end

      tpl = R8Tpl::TemplateR8.new("workspace/wspace_search_#{model_name}_2",user_context())
      tpl.set_js_tpl_name("wspace_search_#{model_name}_2")
      tpl.assign('model_list',model_list)

      slide_width = 170*model_list.size
      tpl.assign('slide_width',slide_width)
      slider_id_prefix = (request.params['slider_id_prefix']) ? request.params['slider_id_prefix'] : model_name
      tpl.assign('slider_id_prefix',slider_id_prefix)

      #TODO: needed to below back in so template did not barf
 # }
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("model_name",model_name)

      tpl_result = tpl.render()

      tpl_result[:panel] = (request.params['panel_id']) ? request.params['panel_id'] : model_name+'-search-list-container'
      
      return tpl_result
    end

    def ret_node_group_search_object(filter_params)
      model_name = :node_group
      parent_model_name = :datacenter
      #for processing :parent_id
      parent_id_field_name = ModelHandle.new(ret_session_context_id(),model_name,parent_model_name).parent_id_field_name()
      filter = [:and] + filter_params.map do |k,v|
        [:eq, k == :parent_id ?  parent_id_field_name : k, v]
      end
      hash = {
        "search_pattern" => {
          :relation => model_name,
          :filter => filter,
          :columns => [:id, :display_name]
        }
      } 
      SearchObject.create_from_input_hash(hash,:workspace,ret_session_context_id())
    end

  end
end
