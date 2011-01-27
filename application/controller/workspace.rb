module XYZ
  class WorkspaceController < Controller
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

        update_rows = model_items.map do |item_id,info|
          {
            :id => item_id.to_i, 
            :ui  => {ws_id.to_s.to_sym =>
              {:left => info["pos"]["left"].gsub(/[^0-9]+/,""),
                :top => info["pos"]["top"].gsub(/[^0-9]+/,"")}
            }
          }
        end
        Model.update_from_rows(model_handle,update_rows,:partial_value=>true)
        
#TODO: remove debug statement
pp [:model_name,model_name]
pp [:model_items,model_items]
pp [:debug_stored_new_pos,get_objects(model_name,SQL.in(:id,model_items.map{|item|item[0].to_i}),Model::FieldSet.opt([:id,:ui],model_name))]
      end
      return {}
    end


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
      i18n = get_i18n_mappings_for_models(model_name.to_sym)
      model_list.each_with_index do |model,index|
        model_list[index][:model_name] = model_name
        body_value = ''
        model_list[index][:ui] ||= {}
        model_list[index][:ui][:images] ||= {}
        name = model_list[index][:display_name]
        title = name.nil? ? "" : i18n_string(i18n,model_name.to_sym,name.to_sym)
        img_value = model_list[index][:ui][:images][:tnail] ? 
        '<div class="img_wrapper"><img title="'+title+'"src="'+R8::Config[:base_images_uri]+'/'+model_name+'Icons/'+model_list[index][:ui][:images][:tnail]+'"/></div>' : 
          ""
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
2
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
pp [:datacenter_id,datacenter_id]
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
=begin

      model_list.each_with_index do |node_group,index|
        model_list[index][:model_name] = model_name
        model_list[index][:ui].nil? ? model_list[index][:ui] = {} : nil
        model_list[index][:ui][datacenter_id.to_sym].nil? ? model_list[index][:ui][datacenter_id.to_sym] = {} : nil
        model_list[index][:ui][datacenter_id.to_sym][:top].nil? ? model_list[index][:ui][datacenter_id.to_sym][:top] = top : nil
        model_list[index][:ui][datacenter_id.to_sym][:left].nil? ? model_list[index][:ui][datacenter_id.to_sym][:left] = left : nil

        top = top+50
        left = left+50

        item = {
          :type => model_name,
          :object => model_list[index],
          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info[:template_callback]
        }
        items << item
      end
=end
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

      top = 100
      left = 200

      node_list.each do |node|
        node[:ui].nil? ? node[:ui] = {} : nil
        node[:ui][datacenter_id.to_sym].nil? ? node[:ui][datacenter_id.to_sym] = {} : nil
        node[:ui][datacenter_id.to_sym][:top].nil? ? node[:ui][datacenter_id.to_sym][:top] = top : nil
        node[:ui][datacenter_id.to_sym][:left].nil? ? node[:ui][datacenter_id.to_sym][:left] = left : nil
#pp node[:display_name]
#pp '))))))))))))))))))))))))))))))))))))'
        item = {
          :type => model_name.to_s,
          :object => node,
          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info[:template_callback],
          :ui => node[:ui][datacenter_id.to_sym]
        }
        top = top+50
        left = left+50

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

   #### actions to process pending changes
    helper :get_pending_changes
    helper :create_tasks_from_pending_changes
    helper :i18n_string_mapping

    def commit_changes(datacenter_id=nil)
#pp [:threads, Thread.list]
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

      errors = ValidationError.find_missing_required_attributes(top_level_task)
      if errors
        run_javascript("R8.Workspace.showAlert('Commit errors for missing attrs');")
        return {}
      end

      test_str = "pending changes:\n" 
      pending_changes.each do |sc|
        test_str << "  type=#{sc[:type]}; id=#{(sc[:component]||sc[:node])[:id].to_s}; name=#{(sc[:component]||sc[:node])[:display_name]||'UNSET'}\n"
      end
#=begin
      top_level_task.save!()
      workflow = Workflow.create(top_level_task)

      Ramaze.defer do
        begin
          puts "in commit_changes defer"
          pp request.params
          workflow.execute()
        rescue Exception => e
          Log.error("error in commit background job: #{e.inspect}")
pp e.backtrace
        end
        puts "end of commit_changes defer"
        puts "----------------"
      end
#=end

      run_javascript("R8.Workspace.showAlert('Commit Logged,Pending Execution');")
 #     return {}
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
          pp [:commit_tree,commit_tree]
          delete_instance(commit_task.id())
        end
      end

#      tpl = R8Tpl::TemplateR8.new("workspace/commit_test",user_context())
#      panel_id = request.params['panel_id']

      tpl = R8Tpl::TemplateR8.new("workspace/commit",user_context())
      tpl.assign(:_app,app_common())

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

  end
end



