module XYZ
  class NodeController < Controller

    def wspace_display(id)
      c = ret_session_context_id()
      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())

      tpl.set_js_tpl_name('node_wspace_display')
#      node = get_object_by_id(id)
 #     node.delete(:image_size)
      node = Node.get_wspace_display(IDHandle[:c => c, :guid => id])

#TODO: temp hack to stub things out
node[:operational_status] = 'good'
node[:model_name] = 'node'

      tpl.assign(:node,node)
      tpl.assign(:base_images_uri,R8::Config[:base_images_uri])

      num_components = (node[:component]||[]).map{|x|x[:id]}.uniq.size
      tpl.assign(:num_components,num_components)

      _node_vars = {}
      _node_vars[:i18n] = get_model_i18n("node",user_context())
      tpl.assign("_node",_node_vars)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'viewspace'
      tpl_result[:assign_type] = 'append'

      return tpl_result
    end

    def wspace_refresh(id)
      c = ret_session_context_id()
      tpl = R8Tpl::TemplateR8.new("node/wspace_refresh",user_context())

      tpl.set_js_tpl_name('node_wspace_refresh')
#      node = get_object_by_id(id)
 #     node.delete(:image_size)
      node = Node.get_wspace_display(IDHandle[:c => c, :guid => id])

#TODO: temp hack to stub things out
node[:operational_status] = 'good'
node[:model_name] = 'node'

      tpl.assign(:node,node)
      tpl.assign(:base_images_uri,R8::Config[:base_images_uri])

      num_components = (node[:component]||[]).map{|x|x[:id]}.uniq.size
      tpl.assign(:num_components,num_components)

      _node_vars = {}
      _node_vars[:i18n] = get_model_i18n("node",user_context())
      tpl.assign("_node",_node_vars)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'item-'+node[:id].to_s
#      tpl_result[:assign_type] = 'append'
p 'Panel IS:'+tpl_result[:panel]

      return tpl_result
    end

    def get_components(id)
      model_name = :component
      field_set = Model::FieldSet.default(model_name)
      component_list = get_objects(model_name,{:node_node_id=>id})

#pp model_list
      component_i18n = get_model_i18n('component',user_context())

      component_list.each do |component|
        pp '--------------------'
        pp 'component:'+component[:display_name]
        pp 'id:'+component[:id].to_s
        component_name = component[:display_name].gsub('::','_')
        component[:label] = component_i18n[component_name.to_sym]
        component[:onclick] = "R8.Workspace.Dock.loadDockPanel('component/wspace_dock_get_attributes/#{component[:id].to_s}');"
#        component[:onclick] = "R8.Workspace.Dock.loadDockPanel('node/get_components/2147484111');"
      end

      component_list[0][:css_class] = 'first'
      component_list[component_list.length-1][:css_class] = 'last'

      tpl = R8Tpl::TemplateR8.new("workspace/dock_list",user_context())
#      tpl.assign(:component_list,component_list)
      js_tpl_name = 'wspace_dock_list'
      tpl.set_js_tpl_name(js_tpl_name)
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      panel_id = request.params['panel_id']

      panel_cfg_hash = {
        :title=>{
          :i18n=>component_i18n[:components]
        },
        :item_list=>component_list,
      }
      panel_cfg = JSON.generate(panel_cfg_hash)
#TODO: temp pass of
      run_javascript("R8.Workspace.Dock.pushDockPanel2('0',#{panel_cfg},'#{js_tpl_name}');")

      return {}

=begin
      return {:data=>{
          :panel_cfg=>panel_cfg
        }
      }
      return {
#        :content=>tpl.render(),
        :data=> {
          :component_list => component_list
        },
        :panel=>panel_id
      }
=end
    end
  end
end

