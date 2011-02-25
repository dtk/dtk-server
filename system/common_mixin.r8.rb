module R8Tpl
  module CommonMixin
    
    #temp until deprecate @saved_search_ref
    def virtual_model_ref()
      @virtual_model_ref || @saved_search_ref
    end

    #returns the appropriate view path
    #TODO: this bakes in some "ordering with a type; is this right place to put this?
    def ret_view_path(type)
      case(type)
       when :system 
        ViewPath.new(:file,"#{R8::Config[:system_views_dir]}/#{@profile}.#{@view_name}.rtpl")
       when :base 
        ViewPath.new(:file,"#{R8::Config[:base_views_dir]}/#{@model_name}/#{@profile}.#{@view_name}.rtpl")
       when :meta
        #first see if there is a meta template for specfic profile type; if not look for default;
        path = ret_if_exists(ViewPath.new(:file,"#{R8::Config[:meta_templates_root]}/#{@model_name}/view.#{@profile}.#{@view_name}.rb"))
        return path if path
        return nil if @profile.to_sym == :default
        ViewPath.new(:file,"#{R8::Config[:meta_templates_root]}/#{@model_name}/view.default.#{@view_name}.rb")
       when :cache 
        if virtual_model_ref
          ViewPath.new(:file,"#{R8::Config[:app_cache_root]}/view/saved_search/#{@profile}.#{virtual_model_ref}.rtpl")
        else
          ViewPath.new(:file,"#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.rtpl")
        end
       when :layout
        #TODO: see if profile is used to qualify
        ViewPath.new(:file,"#{R8::Config[:app_root_path]}/view/#{@view_name}.rtpl")
       when :css_require
        ViewPath.new(:file,"#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.css_include.json")
       when :js_require
        ViewPath.new(:file,"#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.js_include.json")
       else
        Log.error("call to ret_view_path with no handler for type: #{type}")
        nil
      end
    end

    class ViewPath < String
      def initialize(type,path)
        super(path)
        @type = type
      end
      attr_reader :type
    end

    #returns the appropriate view path if it exists
    def ret_existing_view_path(type)
      ret_if_exists(ret_view_path(type))
    end

    def ret_if_exists(path)
      return nil unless path
      case path.type
        when :file then File.exists?(path) ? path : nil
        when :db then path
      else 
        Log.error("Unexpected type of path")
        nil
      end
    end
  end
end
