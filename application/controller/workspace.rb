module XYZ
  class WorkspaceController < AuthController
    helper :i18n_string_mapping

    def index()
      projects = Project.get_all(model_handle(:project))
      pp [:projects,projects]

      projects.each_with_index { |p,i|
        projects[i][:tree] = {}
        projects[i][:tree][:targets] = p.get_target_tree()
        projects[i][:tree][:implementations] = p.get_module_tree(:include_file_assets => true)
        projects[i][:name] = projects[i][:display_name]
      }
      tpl = R8Tpl::TemplateR8.new("ide/project_tree_leaf",user_context())
      tpl.set_js_tpl_name("project_tree_leaf")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("ide/l_panel",user_context())
      tpl.set_js_tpl_name("l_panel")
#      tpl = R8Tpl::TemplateR8.new("ide/panel_frame",user_context())
#      tpl.set_js_tpl_name("ide_panel_frame")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("ide/editor_panel",user_context())
      tpl.set_js_tpl_name("editor_panel")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

#==========================
#Include target specific js that will be needed
#TODO: move out of here eventually
      tpl_info_hash = Hash.new

      tpl = R8Tpl::TemplateR8.new("node_group/wspace_display",user_context())
      tpl.set_js_tpl_name("ng_wspace_display")
      tpl_info_hash[:node_group] = tpl.render()
      include_js_tpl(tpl_info_hash[:node_group][:src])

      tpl = R8Tpl::TemplateR8.new("node/wspace_display_ide",user_context())
      tpl.set_js_tpl_name("node_wspace_display_ide")
      tpl_info_hash[:node] = tpl.render()
      include_js_tpl(tpl_info_hash[:node][:src])

      tpl = R8Tpl::TemplateR8.new("datacenter/wspace_monitor_display",user_context())
      tpl.set_js_tpl_name("wspace_monitor_display")
      tpl_info_hash[:monitor] = tpl.render()
      include_js_tpl(tpl_info_hash[:monitor][:src])

      tpl = R8Tpl::TemplateR8.new("workspace/notification_list_ide",user_context())
      tpl.set_js_tpl_name("notification_list_ide")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("component/library_search",user_context())
      tpl.set_js_tpl_name("component_library_search")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("node/library_search",user_context())
      tpl.set_js_tpl_name("node_library_search")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("assembly/library_search",user_context())
      tpl.set_js_tpl_name("assembly_library_search")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])
#==========================

#      include_js('plugins/search.cmdhandler2')
      include_js('plugins/r8.cmdbar.assemblies')
      include_js('plugins/r8.cmdbar.components')
      include_js('plugins/r8.cmdbar.nodes')
      include_js('plugins/r8.cmdbar.tasks')

      projects_json = JSON.generate(projects)
#TODO: figure out why this user init isnt firing inside of bundle and return
#DEBUG
      run_javascript("R8.User.init();")
      run_javascript("R8.IDE.init(#{projects_json});")

#      run_javascript("R8.IDE.addProjects(#{projects_json});")

#      tpl = R8Tpl::TemplateR8.new("ide/test_tree2",user_context())
#      run_javascript("R8.IDE.testTree();")

      return {:content=>tpl.render(),:panel=>'project_panel'}

#      return {:content=>''}
    end

#TODO: move to viewspace controller
    def update_pos(ws_id)
      items_to_save = JSON.parse(request.params["item_list"])

      return {} if items_to_save.empty?
      
#TODO: patch that maps nil model_name to node_group
items_to_save.values.each{|item|item["model"] ||= "node_group"}

      #partition into model types
      model_names = items_to_save.values.map{|item|item["model"].to_sym}.uniq
      model_names.each do |model_name| 
        model_handle = ModelHandle.new(ret_session_context_id(),model_name)

        model_items = items_to_save.reject{|item_id,info|not info["model"].to_sym == model_name}
        
        #TODO: temp hack; adn expensive call taht shoudl be removed; make sure that items_to_save all have ws_id as parent; hack now assumeing ws_id is just datacenter
        parent_field = :datacenter_datacenter_id
        model_items.reject! do |item_id,info|
          idh = id_handle(item_id.to_i,info["model"].to_sym)
          if idh[:parent_model_name] == :datacenter
            false
          else
            obj_info = idh.create_object.get_objects_from_sp_hash(:columns => [parent_field]).first
            not (obj_info||{})[parent_field] == (ws_id && ws_id.to_i)
          end
        end
        #############################################


        update_rows = model_items.map do |item_id,info|
          {
            :id => item_id.to_i, 
            :ui  => {ws_id.to_s.to_sym =>
              {:left => info["pos"]["left"].gsub(/[^0-9]+/,"").to_i,
                :top => info["pos"]["top"].gsub(/[^0-9]+/,"").to_i}
            }
          }
        end
        Model.update_from_rows(model_handle,update_rows,:partial_value=>true)
        
#TODO: remove debug statement
=begin
pp [:model_name,model_name]
pp [:model_items,model_items]
pp [:debug_stored_new_pos,get_objects(model_name,SQL.in(:id,model_items.map{|item|item[0].to_i}),Model::FieldSet.opt([:id,:ui],model_name))]
=end
      end
      return {}
    end

=begin
    def index
#TODO: make call to load the users/system already in use plugins,cmds,etc
#      include_js('plugins/search.cmdhandler')
#TODO: remove this after fully getting viewspaces going
#      add_js_exe("R8.Workspace.setupNewItems();")
#      add_js_exe("R8.Toolbar.init({node:'group-01',tools:['quicksearch']});")
      include_js('plugins/search.cmdhandler')

      return {
        :content=>'',
        :panel=>'viewspace'
      }
    end
=end

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
      params = request.params.dup
      model_name = params.delete("model_name").to_sym
      #TODO: hack to get around restriction type = template does not allow one to see assemblies
      #TODO: need to determine how to handle an assembly that is a template; may just assume everything in library is template
      #and then do away with explicitly setting type to "template"
      params.delete("type") if model_name == :component
      cols = model_class(model_name).common_columns()
      filter_conjuncts = params.map do |name,value|
        [:regex,name.to_sym,"^#{value}"] if cols.include?(name.to_sym)
      end.compact
      #restrict results to belong to library and not nested in assembly
      filter_conjuncts += [[:neq,:library_library_id,nil],[:eq,:assembly_id,nil]]
      sp_hash = {
        :cols => cols,
        :filter => [:and] + filter_conjuncts
      }
      model_list = Model.get_objs(model_handle(model_name),sp_hash).each{|r|r.materialize!(cols)}

      i18n = get_i18n_mappings_for_models(model_name)
      model_list.each_with_index do |model,index|
#pp model
        model_list[index][:model_name] = model_name
        body_value = ''
        model_list[index][:ui] ||= {}
        model_list[index][:ui][:images] ||= {}
        name = model_list[index][:display_name]
        title = name.nil? ? "" : i18n_string(i18n,model_name,name)

        #TDOO: temporary to distingusih between chef and puppet components
        if model_name == :component
          if config_agent_type = model_list[index][:config_agent_type]
            title += " (#{config_agent_type[0].chr})" 
          end
        end
        
#TODO: change after implementing all the new types and making generic icons for them
        model_type = 'service'
        model_sub_type = 'db'
        model_type_str = "#{model_type}-#{model_sub_type}"
        prefix = "#{R8::Config[:base_images_uri]}/#{model_name}Icons"
        png = model_list[index][:ui][:images][:tnail] || "unknown-#{model_type_str}.png"
        model_list[index][:image_path] = "#{prefix}/#{png}"

        model_list[index][:i18n] = title

=begin
        img_value = model_list[index][:ui][:images][:tnail] ? 
        '<div class="img_wrapper"><img title="'+title+'"src="'+R8::Config[:base_images_uri]+'/'+model_name+'Icons/'+model_list[index][:ui][:images][:tnail]+'"/></div>' : 
          ''
        body_value = img_value
          
        body_value == '' ? body_value = model_list[index][:display_name] : nil
        model_list[index][:body_value] = body_value
=end
      end

#pp "^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
#pp model_list
#pp "^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

      tpl = R8Tpl::TemplateR8.new("workspace/wspace_search_#{model_name}",user_context())
      tpl.set_js_tpl_name("wspace_search_#{model_name}")
      tpl.assign('model_list',model_list)

      slide_width = 130*model_list.size
      tpl.assign('slide_width',slide_width)
      #TODO: needed to below back in so template did not barf
 # }
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name,user_context())
      tpl.assign("_workspace",_model_var)
      tpl.assign("model_name",model_name.to_s)

      tpl_result = tpl.render()
      tpl_result[:panel] = "#{model_name}-search-list-container"
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

      run_javascript("R8.Workspace.setupNewItems();")
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
#2
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

=begin
    def list_items_2(datacenter_id)
      datacenter = id_handle(datacenter_id,:datacenter).create_object()
      datacenter_id = datacenter.id()

      include_js('plugins/search.cmdhandler')
      view_space = {
        :type => 'datacenter',
        :object => datacenter
      }
      v_space_obj = JSON.generate(view_space)
      run_javascript("R8.Workspace.pushViewSpace(#{v_space_obj});")

      #--------Setup Toolbar for access each group from ACL's---------
      #        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[0][:id]}',tools:['quicksearch']});")
      user_has_toolbar_access = true
      user_group_tool_list = Array.new
      user_group_tool_list << 'quicksearch'
      toolbar_def = {:tools => user_group_tool_list}

      include_js('toolbar.quicksearch.r8')

      tpl_info_hash = Hash.new

      tpl = R8Tpl::TemplateR8.new("node_group/wspace_display",user_context())
      tpl.set_js_tpl_name("ng_wspace_display")
      tpl_info_hash[:node_group] = tpl.render()
      include_js_tpl(tpl_info_hash[:node_group][:src])

      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())
      tpl.set_js_tpl_name("node_wspace_display")
      tpl_info_hash[:node] = tpl.render()
      include_js_tpl(tpl_info_hash[:node][:src])

      ##### ----------------- add in model info
      model_list = datacenter.get_items()

      items = model_list.map do |object|
        model_name = object.model_name
        {
          :type => model_name.to_s,
          :object => object,
          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info_hash[model_name][:template_callback],
          :ui => object[:ui][datacenter_id.to_s.to_sym]
        }
      end

      addItemsObj = JSON.generate(items)
      run_javascript("R8.Workspace.addItems(#{addItemsObj});")

      #---------------------------------------------

      return {
        :content => '',
        :panel => 'viewspace'
      }
    end
=end

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
        model_list[index][:ui] ||= {}
        model_list[index][:ui][:images] ||= {}
        img_value = model_list[index][:ui][:images][:tnail] ? img_value = '<div class="img_wrapper"><img title="' << model_list[index][:display_name] << '"' << 'src="' << R8::Config[:base_images_uri] << '/' << model_name << 'Icons/'<< model_list[index][:ui][:images][:tnail] << '"/></div>' : ""
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

    #TODO: check if this and its referents are deprecated
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


    #deprecate
    def commit_changes(datacenter_id=nil)
#      context_type = request.params["context_type"]
      #TODO: either use param from context id or from what is posted
      #TODO: move to getting id of top level task
      context_id = request.params["context_id"]
      datacenter_id ||= context_id

      datacenter_id = datacenter_id && datacenter_id.to_i

      pending_changes = flat_list_pending_changes_in_datacenter(datacenter_id)
      if pending_changes.empty?
        run_javascript("R8.Workspace.showAlert('No Pending Changes to Commit');")
        return {}
      end

      top_level_task = create_task_from_pending_changes(pending_changes)

      #TODO: need to sync ValidationError with analysis done in group by
      errors = Violation.find_missing_required_attributes(top_level_task)
#TODO: removing for time being
#      if errors
      pp [:errors,errors] if errors
      if false
        error_list = []
        #TODO: stub
        i18n = {
          "MissingRequiredAttribute"=>'is missing required Attribute'
        }
        alert_msg = "'Commit errors for missing attrs'"
        error_str = "Commit errors for missing attrs<br/>"
        errors.each { |e|
          error_name = Aux::demodulize(e.class.to_s)
          case error_name
            when "MissingRequiredAttribute"
              error_description = "Component <b>#{e[:component_name]}</b> on node <b>#{e[:node_name]}</b> "+i18n[error_name]+"#{e[:attribute_name]}"
          end
#TODO: revisit when fully implementing notifications/feed, right now warnings on component add are different then commit errors
          e[:name] = error_name
          e[:target_node_id] = e[:node_id]
          e[:description] = error_description
          e[:type] = "error"
          error_list << e
         }
        run_javascript("R8.Workspace.showAlert(#{alert_msg});")
        error_list_json = JSON.generate(error_list)
        run_javascript("R8.Notifications.addErrors(#{error_list_json});")
        return {}
      end

      test_str = "pending changes:\n" 
      pending_changes.each do |sc|
        test_str << "  type=#{sc[:type]}; id=#{(sc[:component]||sc[:node])[:id].to_s}; name=#{(sc[:component]||sc[:node])[:display_name]||'UNSET'}\n"
      end

      top_level_task.save!()
      workflow = Workflow.create(top_level_task)
      workflow.defer_execution()

      run_javascript("R8.Workspace.showAlert('Commit Logged,Pending Execution');")
      return {
        'data'=>test_str
      }
    end

    #TODO: doing redundant work to what is done in commit_ide
    def commit_changes_ide(target_id)
      target_id = target_id.gsub(/editor-target-/,"") #TODO: temp to compensate front end error

      target_idh = id_handle(target_id,:target) 
      hash = request.params.dup
      commit_date = hash.delete("commit_date")
      commit_msg = hash.delete("commit_msg")

      #save any params given
      attr_val_hash = hash
      attr_val_hash.each{|k,v|attr_val_hash[k] = nil if v.kind_of?(String) and v.empty?}
      #TODO: if not using c_ prfix remove from view and remobe below
      attr_val_hash = attr_val_hash.inject({}) do |h,(k,v)|
        h.merge(k.gsub(/^c__[0-9]+__/,"") => v)
      end
      attribute_rows = AttributeComplexType.ravel_raw_post_hash(attr_val_hash,:attribute)
      Attribute.update_and_propagate_attributes(target_idh.createMH(:attribute),attribute_rows)
      ######
      pending_changes = StateChange.flat_list_pending_changes(target_idh)
      if pending_changes.empty?
        run_javascript("R8.IDE.showAlert('No Pending Changes to Commit');")
        return {}
      end

      top_level_task = Task.create_from_pending_changes(target_idh,pending_changes)

      #TODO: need to sync Violation with analysis done in group by
      #TODO: just need to check if anything returned missing values
      errors = Violation.find_missing_required_attributes(top_level_task)
      #TODO: removing for time being
      #      if errors
      if false #errors
        pp [:errors,errors]
        error_list = []
        #TODO: stub
        i18n = {
          "MissingRequiredAttribute"=>'is missing required Attribute'
        }
        alert_msg = "'Commit errors for missing attrs'"
        error_str = "Commit errors for missing attrs<br/>"
        errors.each { |e|
          error_name = Aux::demodulize(e.class.to_s)
          case error_name
            when "MissingRequiredAttribute"
              error_description = "Component <b>#{e[:component_name]}</b> on node <b>#{e[:node_name]}</b> "+i18n[error_name]+"#{e[:attribute_name]}"
          end
#TODO: revisit when fully implementing notifications/feed, right now warnings on component add are different then commit errors
          e[:name] = error_name
          e[:target_node_id] = e[:node_id]
          e[:description] = error_description
          e[:type] = "error"
          error_list << e
         }
        run_javascript("R8.IDE.showAlert(#{alert_msg});")
        error_list_json = JSON.generate(error_list)
#        run_javascript("R8.Notifications.addErrors(#{error_list_json});")
        return {}
      end

      test_str = "pending changes:\n" 
      pending_changes.each do |sc|
        test_str << "  type=#{sc[:type]}; id=#{(sc[:component]||sc[:node])[:id].to_s}; name=#{(sc[:component]||sc[:node])[:display_name]||'UNSET'}\n"
      end

      top_level_task.save!()

      guards = Attribute.ret_attribute_guards(top_level_task)

      workflow = Workflow.create(top_level_task,guards)
      workflow.defer_execution()

      run_javascript("R8.IDE.showAlert('Commit Logged,Pending Execution');")
      return {
        'data'=>test_str
      }
    end

    def commit(datacenter_id=nil)
      commit_tree = Hash.new
      if datacenter_id
#TODO: Move pending changes retrive inside of create_commit_task
        pending_changes = flat_list_pending_changes_in_datacenter(datacenter_id.to_i)
        unless pending_changes.empty?
#TODO: cleanup interface to tasks/pending changes
#          commit_task = create_commit_task()
#default gets all pending changes since last commit by user

#group can be either datacenter, node_group, node,
#later figure out how to 
#          commit_task = create_commit_task(group_id)
          commit_task = create_task_from_pending_changes(pending_changes)
          commit_task.save!()
=begin
POSSIBLE CHANGES TO HASH
  -task_id to id
  -
=end


#default if nothing passed is json, make extensible for xml formatting for tuture possible integrations
#          commit_tree = top_level_task.render_commit_tree()
#          commit_tree = top_level_task.render_commit_tree('xml | json')
          commit_tree = commit_task.render_form()
          add_i18n_strings_to_rendered_tasks!(commit_tree)
#          pp [:commit_tree,commit_tree]
          delete_instance(commit_task.id())
        end
      end

#      tpl = R8Tpl::TemplateR8.new("workspace/commit_test",user_context())
#      panel_id = request.params['panel_id']

      tpl = R8Tpl::TemplateR8.new("workspace/commit",user_context())
      tpl.assign(:_app,app_common())

#TODO: using datacenters as environments right now, redo later on
      dc_hash = get_object_by_id(datacenter_id,:datacenter)
      if dc_hash[:type] == 'production'
        commit_content = '<tr><td class="label">Maintenance Window</td></tr>
                          <tr><td class="field"><select id="commit_date" name="commit_date">
                            <option value="foo">Prime Window - Tue 10pm</option>
                            <option value="foo">Weekly Window - Fri 8pm</option>
                            <option value="foo">Weekend Warrior - Saturday 8pm</option>
                          </select></td></tr>'
        submit_label = "Schedule Changes"
      else
        commit_content = ""
        submit_label = "Commit"
      end
      tpl.assign(:commit_content,commit_content)
      tpl.assign(:submit_label,submit_label)

      panel_id = request.params['panel_id']

      include_js('plugins/commit.tool')
      include_js('external/jquery.treeview')
      include_css('jquery.treeview')
#      include_js('plugins/user.component')
#      run_javascript('setTimeout(initUserForm,500);')
      commit_tree_json = JSON.generate(commit_tree)

      run_javascript("R8.CommitTool.init();")
      run_javascript("R8.CommitTool.renderTree(#{commit_tree_json},'edit','change-list-tab-content');")

      return {
        :content=> tpl.render(),
        :panel=>panel_id
      }
    end

    def commit_ide(target_id=nil)
      commit_tree = Hash.new
      required_attr_list = Array.new
      if target_id
        target_idh = id_handle(target_id,:target)
        pending_changes = StateChange.flat_list_pending_changes(target_idh)
        unless pending_changes.empty?
          commit_task = Task.create_from_pending_changes(target_idh,pending_changes)
          commit_task.save!()

          #handle missing required attrs
          augmented_attr_list = Attribute.augmented_attribute_list_from_task(commit_task)
        
          opts = {:types_to_keep => [:required]}
          grouped_attrs = Attribute.ret_grouped_attributes!(augmented_attr_list,opts)
  
          i18n_mapping = get_i18n_mappings_for_models(:attribute,:component)
          required_attr_list = grouped_attrs.map do |a|
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

          #default if nothing passed is json, make extensible for xml formatting for tuture possible integrations
          #commit_tree = top_level_task.render_commit_tree()
          #commit_tree = top_level_task.render_commit_tree('xml | json')
          commit_tree = commit_task.render_form()
          add_i18n_strings_to_rendered_tasks!(commit_tree)
          delete_instance(commit_task.id())
        end
      end

#      tpl = R8Tpl::TemplateR8.new("workspace/commit_test",user_context())
#      panel_id = request.params['panel_id']

      tpl = R8Tpl::TemplateR8.new("workspace/commit_ide",user_context())
      tpl.assign(:_app,app_common())

      if required_attr_list.length == 0
        tpl.assign(:no_required_attrs,'<tr><td class="label"><i>No Required Attributes Missing</i></td></tr>')
      else
        tpl.assign(:no_required_attrs,'<tr><td class="label"><i></i></td></tr>') #TODO: to get aroudn template bug
      end
      tpl.assign(:required_attr_list,required_attr_list)

#TODO: using datacenters as environments right now, redo later on
      dc_hash = get_object_by_id(target_id,:datacenter)
      if dc_hash[:type] == 'production'
        commit_content = '<tr><td class="label">Maintenance Window</td></tr>
                          <tr><td class="field"><select id="commit_date" name="commit_date">
                            <option value="foo">Prime Window - Tue 10pm</option>
                            <option value="foo">Weekly Window - Fri 8pm</option>
                            <option value="foo">Weekend Warrior - Saturday 8pm</option>
                          </select></td></tr>'
        submit_label = "Schedule Changes"
      else
        commit_content = ""
        submit_label = "Commit"
      end
      tpl.assign(:commit_content,commit_content)
      tpl.assign(:submit_label,submit_label)

      panel_id = request.params['panel_id']

      include_js('plugins/commit.tool3')
#      include_js('plugins/commit.tool')
      include_js('external/jquery.treeview')
      include_css('jquery.treeview')
#      include_js('plugins/user.component')
#      run_javascript('setTimeout(initUserForm,500);')
      commit_tree_json = JSON.generate(commit_tree)

      run_javascript("R8.CommitTool3.init();")
#      run_javascript("R8.CommitTool3.renderTree(#{commit_tree_json},'edit','change-list-tab-content');")

      return {
        :content=> tpl.render(),
        :panel=>panel_id
      }
    end

    #TODO: just for testing this gets a datacenter id
    def commit_test(datacenter_id=nil)
      if datacenter_id
        pending_changes = flat_list_pending_changes_in_datacenter(datacenter_id.to_i)
        unless pending_changes.empty?
          top_level_task = create_task_from_pending_changes(pending_changes)
          top_level_task.save!()
          rendered_tasks = top_level_task.render_form()
          pp [:rendered_tasks,rendered_tasks]
          delete_instance(top_level_task.id())
        end
      end

      tpl = R8Tpl::TemplateR8.new("workspace/commit_test",user_context())
      panel_id = request.params['panel_id']

      include_js('plugins/commit.tool')
      include_js('external/jquery.treeview')
      include_css('jquery.treeview')
#      include_js('plugins/user.component')
#      run_javascript('setTimeout(initUserForm,500);')
      run_javascript('R8.CommitTool.init();')

      return {
        :content=> tpl.render(),
        :panel=>panel_id
      }
    end

    def create_assembly()

      tpl = R8Tpl::TemplateR8.new("workspace/create_assembly",user_context())
      tpl.assign(:_app,app_common())
      panel_id = request.params['panel_id']

      where_clause = {}
      if where_clause
        where_clause = where_clause.inject(nil){|h,o|SQL.and(h,SQL::WhereCondition.like(o[0],"#{o[1]}%"))}
      end
      library_list = get_objects(:library,where_clause)
      lib_num = 1
      library_list.each do |library|
        library[:name] = "Library "+lib_num.to_s if library[:name].nil?
        lib_num = lib_num+1
      end
      tpl.assign(:library_list,library_list)

      include_js('plugins/assembly.tool')
#      include_js('external/jquery.treeview')
#      include_css('jquery.treeview')

      run_javascript('R8.AssemblyTool.init();')

      return {
        :content=> tpl.render(),
        :panel=>panel_id
      }
    end

    def create_assembly_ide()

      tpl = R8Tpl::TemplateR8.new("workspace/create_assembly",user_context())
      tpl.assign(:_app,app_common())
      panel_id = request.params['panel_id']

      where_clause = {}
      if where_clause
        where_clause = where_clause.inject(nil){|h,o|SQL.and(h,SQL::WhereCondition.like(o[0],"#{o[1]}%"))}
      end
      library_list = get_objects(:library,where_clause)
      lib_num = 1
      library_list.each do |library|
        library[:name] = "Library #{(library[:display_name]||"").capitalize}"
        lib_num = lib_num+1
      end
      tpl.assign(:library_list,library_list)

      project = get_default_project()
      service_list = ServiceModule.list(model_handle(:service_module), :project_idh => project.id_handle()).map do |r|
        {
          :id => r[:id],
          :name => "#{r[:display_name]}#{r[:version] && "-#{r[:version]}"}"
        }
      end
=begin
	  service_list = Array.new
	  service_list = [
	  	{:id=>1234,:name=>'Service One'},
	  	{:id=>1235,:name=>'Service Two'}
	  ]
=end
      tpl.assign(:service_list,service_list)

      include_js('plugins/assembly.tool2')
#      include_js('external/jquery.treeview')
#      include_css('jquery.treeview')

      run_javascript('R8.AssemblyTool2.init();')

      return {
        :content=> tpl.render(),
        :panel=>panel_id
      }
    end

    def clone_assembly(explicit_hash=nil)
      hash = explicit_hash || request.params
      #TODO: stub
      icon_info = {"images" => {"display" => "generic-assembly.png","tiny" => "","tnail" => "generic-assembly.png"}}

      library_id = hash["library_id"].to_i
      library_idh = id_handle(library_id,:library)
      name = hash["name"] || "assembly"
      create_row = {
        :library_library_id => library_id,
        :ref => name,
        :display_name => name,
        :ui => icon_info,
        :type => "composite"
      }
      assembly_mh = library_idh.createMH(:model_name=>:component,:parent_model_name=>:library)
      assembly_idh = Model.create_from_row(assembly_mh,create_row,:convert=>true)

      #TODO: getting json rather than hash
      item_list = JSON.parse(hash["item_list"])
      node_idhs = item_list.map{|item|id_handle(item["id"].to_i,item["model"].to_sym)}
      connected_links,dangling_links = Node.get_external_connected_links(node_idhs)
      #TODO: raise error to user if dangling link
      Log.error("dangling links #{dangling_links.inspect}") unless dangling_links.empty?
      link_idhs = connected_links.map{|link|link.id_handle}

      id_handles = node_idhs + link_idhs
      library_object = library_idh.create_object()
      #TODO: encapsulate some of above so ca just call library_object.clone_into(...
      library_object.clone_into_library_assembly(assembly_idh,id_handles)
      return {:content => nil}
    end

    def clone_assembly_ide(explicit_hash=nil)
      #TODO: temp hack
      assembly_name, service_id = ret_non_null_request_params(:name,:service_id)
      item_list = JSON.parse(ret_non_null_request_params(:item_list))
      icon_info = {"images" => {"display" => "generic-assembly.png","tiny" => "","tnail" => "generic-assembly.png"}}

      service = id_handle(service_id,:service_module).create_object.update_object!(:display_name,:library_library_id)
      service_module_name = service[:display_name]

      #TODO remove DEMOHACK
      node_idhs = item_list.map do |item|
        id = item["id"].to_i
        model = (item["model"].nil? or item["model"].empty?) ? :node : item["model"].to_sym
        id_handle(id,model)
      end
      project = get_default_project()
      Assembly::Template.create_from_instance(project,node_idhs,assembly_name,service_module_name,icon_info) 
      return {:content => nil}
    end
  end
end



