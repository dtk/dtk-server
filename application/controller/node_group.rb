module XYZ
  class Node_groupController < Controller
    def wspace_refresh(id)
      c = ret_session_context_id()
      tpl = R8Tpl::TemplateR8.new("node_group/wspace_refresh",user_context())

      tpl.set_js_tpl_name('node_group_wspace_refresh')
      node_group = NodeGroup.get_wspace_display(IDHandle[:c => c, :guid => id])

#TODO: temp hack to stub things out
node_group[:model_name] = 'node_group'

      tpl.assign(:node_group,node_group)
      tpl.assign(:base_images_uri,R8::Config[:base_images_uri])

      num_components = node_group[:component].length
      tpl.assign(:num_components,num_components)

      _node_group_vars = {}
      _node_group_vars[:i18n] = get_model_i18n("node_group",user_context())
      tpl.assign("_node_group",_node_group_vars)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'item_'+node_group[:id].to_s
      return tpl_result
    end
  end
end
