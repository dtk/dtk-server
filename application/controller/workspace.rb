module XYZ
  class WorkspaceController < Controller

    def index
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
      field_set = default_field_set(model_name.to_sym)
#      search_query = request.params['sq']

      where_clause = {}
      request.params.each do |name,value|
        (field_set.include?(name.to_sym)) ? where_clause[name.to_sym] = value : nil;
      end

#      where_clause = {:display_name => search_query}
      if where_clause
        where_clause = where_clause.inject(nil){|h,o|SQL.and(h,SQL::WhereCondition.like(o[0],"#{o[1]}%"))}
      end
 
      model_list = get_objects(model_name.to_sym,where_clause)
      model_list.each_with_index do |model,index|
        model_list[index][:model_name] = model_name
          model_list[index][:ui].nil? ? model_list[index][:ui] = {} : nil
          model_list[index][:ui][:images].nil? ? model_list[index][:ui][:images] = {} : nil

          !model_list[index][:ui][:images][:tnail].nil? ? img_value = '<img src="' << R8::Config[:base_images_uri] << '/' << model_name << 'Icons/'<< model_list[index][:ui][:images][:tnail] <<'"/>' : img_value = ""
          model_list[index][:img_value] = img_value
 pp model_list[index][:img_value]
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

  end
end
