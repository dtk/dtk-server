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

  end
end
