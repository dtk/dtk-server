module XYZ
  class ComponentController < Controller
#TODO: move field set out of here and into meta/component/component.defs.rb file
    def self.field_set()
      [
        :id,
        :display_name,
        :type,
        :external_cmp_ref,
        :description,
        :parent_id,
        :parent_path
      ]   
    end

    def testjsonlayout
      tpl = R8Tpl::TemplateR8.new('component/testjson',user_context())
      tpl.assign(:testing, 'Testing')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return {:content => tpl.render()}
    end


    def testjsoncall
      tpl = R8Tpl::TemplateR8.new('component/testjsoncall',user_context())
      tpl.set_js_tpl_name('testjson')
      tpl.assign(:testing, 'Testing')

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return tpl.render()
    end

  end
end
