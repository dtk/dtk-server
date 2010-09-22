module XYZ
  class NodeController < Controller

    def wspace_display(id)
      c = ret_session_context_id()
      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())

      tpl.set_js_tpl_name('node_wspace_display')
#      node = get_object_by_id(id)
 #     node.delete(:image_size)
      node = Node.get_wspace_display(IDHandle[:c => c, :guid => id])
pp node
      tpl.assign(:node,node)

      _node_vars = {}
      _node_vars[:i18n] = get_model_i18n("node",user_context())
      tpl.assign("_node",_node_vars)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'viewspace'
      tpl_result[:assign_type] = 'append'

      return tpl_result
    end

  
  end
end

