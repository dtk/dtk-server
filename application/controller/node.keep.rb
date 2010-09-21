module XYZ
  class NodeController < Controller

    def wspace_display(id)
pp "Getting inside of wspace_display, id is:"+id.to_s

      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())

      tpl.set_js_tpl_name('node_wspace_display')
      node = get_object_by_id(id)
      node.delete(:image_size)
pp node
      tpl.assign(:node,node)

      _node_vars = {}
      _node_vars[:i18n] = get_model_i18n("node",user_context())
      tpl.assign("_node",_node_vars)

      return {:content => tpl.render()}
    end
  
  end
end

