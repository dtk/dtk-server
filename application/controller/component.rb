module XYZ
  class ComponentController < Controller
    def testjsonlayout
      tpl = R8Tpl::TemplateR8.new('component/testjson',user_context())
      tpl.assign(:testing, 'Testing')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return {:content => tpl.render()}
    end


    def testjshello
      tpl = R8Tpl::TemplateR8.new('component/testjshello',user_context())
      tpl.set_js_tpl_name('testjshello')
      tpl.assign(:testing, 'Testing JSON Call Hello')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return tpl.render()
    end

    def testjsgoodbye
      tpl = R8Tpl::TemplateR8.new('component/testjsgoodbye',user_context())
      tpl.set_js_tpl_name('testjsgoodbye')
      tpl.assign(:testing, 'Testing JSON Call Goodbye')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return tpl.render()
    end

    def wspace_dock_get_attributes(id)
      component = get_object_by_id(id)
      component_name = component[:display_name].gsub('::','_')

      model_name = :attribute
      field_set = Model::FieldSet.default(model_name)
      attribute_list = get_objects(model_name,{:component_component_id=>id})

#pp model_list
      component_i18n = get_model_i18n('component',user_context())
      attr_i18n = get_model_i18n('attribute',user_context())

      attribute_list.each do |attribute|
        pp '--------------------'
        
        pp 'component:'+component_name
        pp 'attribute:'+attribute[:display_name]
        attribute_name = attribute[:display_name].gsub('::','_')
        attribute_name = attribute_name.gsub('[','_')
        attribute_name = attribute_name.gsub(']','')
        pp 'attr name:'+attribute_name
        pp 'id:'+attribute[:id].to_s
        #TODO: below is not exactly right; rather than component_name (which could be mysql::server2, mysql::server; want basically component basic type
        attribute[:label] = attr_i18n["#{component_name}__#{attribute_name}".to_sym]||attr_i18n[attribute_name.to_sym]

#        component[:onclick] = "R8.Workspace.Dock.loadDockPanel('component/get_attributes/#{component[:id].to_s}');"
#        component[:onclick] = "R8.Workspace.Dock.loadDockPanel('node/get_components/2147484111');"
      end

      if attribute_list.length == 0
        attribute_list = Array.new
        attribute_list[0] = {
          :label => component_i18n[:no_attributes],
          :id => 'null'
        }
        attribute_list[0][:css_class] = 'first last'
      else
        attribute_list[0][:css_class] = 'first'
        attribute_list[attribute_list.length-1][:css_class] = 'last'
      end

      tpl = R8Tpl::TemplateR8.new("workspace/dock_list",user_context())
#      tpl.assign(:component_list,component_list)
      js_tpl_name = 'wspace_dock_list'
      tpl.set_js_tpl_name(js_tpl_name)
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      panel_id = request.params['panel_id']

      panel_cfg_hash = {
        :title=>{
          :i18n=> component_i18n[component_name.to_sym]
        },
        :item_list=>attribute_list,
      }
      panel_cfg = JSON.generate(panel_cfg_hash)
#TODO: temp pass of
      run_javascript("R8.Workspace.Dock.pushDockPanel2('0',#{panel_cfg},'#{js_tpl_name}');")

      return {}
    end

  end
end
