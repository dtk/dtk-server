module R8Tpl
  module CommonMixin
    def ret_view_path(type)
      case(type)
        when :system 
          "#{R8::Config[:system_views_root]}/#{@profile}.#{@view_name}.rtpl"
        when :base 
          "#{R8::Config[:base_views_root]}/#{@model_name}/#{@profile}.#{@view_name}.rtpl"
        when :meta_with_profile 
          "#{R8::Config[:meta_templates_root]}/#{@model_name}/view.#{@profile}.#{@view_name}.rb"
        when :meta_default
          "#{R8::Config[:meta_templates_root]}/#{@model_name}/view.default.#{@view_name}.rb"
        when :cache 
          "#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.rtpl"
        else
          log("call to ret_view_path with no handler for type: #{type}")
          nil
      end
    end
  end
end
