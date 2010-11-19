module XYZ
  class Node_groupController < Controller

    def wspace_display(id)
      c = ret_session_context_id()
      tpl = R8Tpl::TemplateR8.new("node_group/wspace_display",user_context())

      tpl.set_js_tpl_name('node_group_wspace_display')
#      node = get_object_by_id(id)
 #     node.delete(:image_size)
      node_group = NodeGroup.get_wspace_display(IDHandle[:c => c, :guid => id])

#TODO: temp hack to stub things out
#node[:model_name] = 'node_group'

      tpl.assign(:node_group,node_group)
      tpl.assign(:base_images_uri,R8::Config[:base_images_uri])

      num_components = (node_group[:component]||[]).map{|x|x[:id]}.uniq.size
      num_nodes = (node_group[:node]||[]).map{|x|x[:id]}.uniq.size
      tpl.assign(:num_components,num_components)
      tpl.assign(:num_nodes,num_nodes)

      _node_vars = {}
      _node_vars[:i18n] = get_model_i18n("node_group",user_context())
      tpl.assign("_node_group",_node_vars)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'viewspace'
      tpl_result[:assign_type] = 'append'

      return tpl_result
    end

    def wspace_refresh(id)
      c = ret_session_context_id()
      tpl = R8Tpl::TemplateR8.new("node_group/wspace_refresh",user_context())

      tpl.set_js_tpl_name('node_group_wspace_refresh')
      node_group = NodeGroup.get_wspace_display(IDHandle[:c => c, :guid => id])

#TODO: temp hack to stub things out
node_group[:model_name] = 'node_group'

      tpl.assign(:node_group,node_group)
      tpl.assign(:base_images_uri,R8::Config[:base_images_uri])

      _node_group_vars = {}
      _node_group_vars[:i18n] = get_model_i18n("node_group",user_context())
      tpl.assign("_node_group",_node_group_vars)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'item_'+node_group[:id].to_s
      return tpl_result
    end
  end
end
