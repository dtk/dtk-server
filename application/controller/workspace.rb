module XYZ
  class WorkspaceController < Controller

    def index
#TODO: make call to load the users/system already in use plugins,cmds,etc
      include_js('plugins/search.cmdhandler')
#TODO: remove this after fully getting viewspaces going
      add_js_exe("R8.Workspace.setupNewItems();")
      add_js_exe("R8.Toolbar.init({node:'group-01',tools:['quicksearch']});")
      return {:content=>''}
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

    def list_items
#pp request.params
      model_name = 'node_group'
      field_set = Model::FieldSet.default(model_name.to_sym)

#
      where_clause = {}
#Should be where on all groups for parent/container foo (ie: datacenter, viewspace,etc)
      where_clause[:parent_id] = 'foo'

#      where_clause = {:display_name => search_query}
#TODO: remove the .inject code everywhere, shouldnt have to deal with this inside controllers
      if where_clause
        where_clause = where_clause.inject(nil){|h,o|SQL.and(h,SQL::WhereCondition.like(o[0],"#{o[1]}%"))}
      end
 
      node_group_list = get_objects(model_name.to_sym,where_clause)
      node_group_list.each_with_index do |node_group,index|
        node_group_list[index][:model_name] = model_name
          node_group_list[index][:ui].nil? ? node_group_list[index][:ui] = {} : nil
      end

      tpl = R8Tpl::TemplateR8.new("node_group/wspace_list",user_context())
#Commented out for now to test with normal page rendering
#      tpl.set_js_tpl_name("wspace_list_ng_#{model_name}")
      tpl.assign('node_group_list',model_list)

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("model_name",model_name)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'viewspace'
      return tpl_result
    end

  end
end
