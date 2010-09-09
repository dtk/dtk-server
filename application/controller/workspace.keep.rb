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
      search_query = request.params['sq']
      where_clause = {}
      field_set = [
       :type,
       :ds_source_obj_type,
       :data_source_id,
       :data_source,
       :is_deployed,
       :ancestor_id,
       :architecture,
       :ds_attributes,
       :os,
       :image_size,
#       :ds_key,
       :display_name,
       :ref_num,
       :c,
       :local_id,
       :description,
       :id,
       :ref
      ]
 
      field_set=Model.field_set(:component)
      opts = {:field_set => field_set}
      node_list = get_objects(:node,where_clause,opts)

      tpl = R8Tpl::TemplateR8.new("workspace/nodesearchtest",user_context())
      tpl.set_js_tpl_name('nodesearchtest')
      tpl.assign('node_list',node_list)

      slide_width = 170*node_list.size
      tpl.assign('slide_width',slide_width)
      #TODO: needed to below back in so template did not barf
 # }
      _model_var = {}
      _model_var[:i18n] = get_model_i18n('node',user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'slidecontainer'
      return tpl_result
    end

  end
end