module R8Tpl
  module CommonMixin
    #returns the appropriate view path if it exists
    #TODO: this bakes in some "ordering with a type; is this right place to put this?
    def ret_existing_view_path(type)
      case(type)
        when :system 
          Helper::ret_if_exists("#{R8::Config[:system_views_root]}/#{@profile}.#{@view_name}.rtpl")
        when :base 
          Helper::ret_if_exists("#{R8::Config[:base_views_root]}/#{@model_name}/#{@profile}.#{@view_name}.rtpl")
        when :meta
          #first see if there is a meta template for specfic profile type; if not look for default;
          path = Helper::ret_if_exists("#{R8::Config[:meta_templates_root]}/#{@model_name}/view.#{@profile}.#{@view_name}.rb")
          return path if path
          return nil if @profile.to_sym == :default
          Helper::ret_if_exists("#{R8::Config[:meta_templates_root]}/#{@model_name}/view.default.#{@view_name}.rb")
        when :cache 
          Helper::ret_if_exists("#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.rtpl")
        else
          log("call to ret_view_path with no handler for type: #{type}")
          nil
      end

    end
    module Helper
      def self.ret_if_exists(path)
        File.exists?(path) ? path : nil
      end
    end
  end
end
