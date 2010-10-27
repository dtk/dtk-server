module R8Tpl
  module CommonMixin
    #returns the appropriate view path
    #TODO: this bakes in some "ordering with a type; is this right place to put this?
    def ret_view_path(type)
      case(type)
        when :system 
          "#{R8::Config[:system_views_dir]}/#{@profile}.#{@view_name}.rtpl"
        when :base 
          return "#{R8::Config[:base_views_dir]}/#{@model_name}/#{@profile}.#{@view_name}.rtpl"
        when :meta
          #first see if there is a meta template for specfic profile type; if not look for default;
          path = Helper::ret_if_exists("#{R8::Config[:meta_templates_root]}/#{@model_name}/view.#{@profile}.#{@view_name}.rb")
          return path if path
          return nil if @profile.to_sym == :default
          "#{R8::Config[:meta_templates_root]}/#{@model_name}/view.default.#{@view_name}.rb"
        when :cache 
          if @saved_search_ref
            "#{R8::Config[:app_cache_root]}/view/saved_search/#{@profile}.#{@saved_search_ref}.rtpl"
          else
          "#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.rtpl"
          end
        when :layout
           #TODO: see if profile is used to qualify
          "#{R8::Config[:app_root_path]}/view/#{@view_name}.rtpl"
        when :css_require
          "#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.css_include.json"
        when :js_require
          "#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.js_include.json"
        else
          log("call to ret_view_path with no handler for type: #{type}")
          nil
      end
    end
    #returns the appropriate view path if it exists
    def ret_existing_view_path(type)
      Helper::ret_if_exists( ret_view_path(type))
    end

    module Helper
      def self.ret_if_exists(path)
        return nil unless path
        File.exists?(path) ? path : nil
      end
    end
  end
end
