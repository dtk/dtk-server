module R8Tpl
  module CommonMixin
    class ViewPath < String
      def initialize(path)
        super(path)
      end
    end
    class ViewPathFile < ViewPath
      def initialize(path)
        super(path)
      end

      def type
        :file
      end

      def edit_time_as_int
        File.mtime(self).to_i
      end
    end

    class ViewPathDB < ViewPath
      def initialize(virtual_model_ref)
        super('')
        @virtual_model_ref = virtual_model_ref
        @db_id = virtual_model_ref.to_i
      end
      attr_reader :type, :db_id
      def type
        :db
      end

      def edit_time_as_int
        @virtual_model_ref.edit_time().to_i
      end
    end

    # TODO: may need to refactor slightly when this subsumes saved_search refs
    class VirtualModelRef < String
      public

      def self.create(virtual_model_ref_str,view_type,user)
        virtual_model_ref_str && self.new(virtual_model_ref_str,:virtual_object,view_type,user) #TODO: hard wiring :virtual_object
      end

      private

      def initialize(virtual_model_ref_str,type,view_type,user)
        super(virtual_model_ref_str)
        @user = user
        @type = type
        @view_type = view_type
        @view_meta_id = nil
        @edit_time = nil 
      end

      public

      attr_reader :type

      def view_meta_id
        return @view_meta_id if @view_meta_id
        set_view_meta_info()
        @view_meta_id
      end

      def edit_time
        return @edit_time if @edit_time
        set_view_meta_info()
        @edit_time
      end

      def set_view_meta_info(*args)
        @view_meta_id,@edit_time = args.empty? ? @user.create_object_from_id(db_id).get_view_meta_info(@view_type) : args
      end

      private

      def db_id
        self.to_i
      end
    end
    
    # TODO: temp until deprecate @saved_search_ref
    def virtual_model_ref
      @virtual_model_ref || @saved_search_ref
    end

    def virtual_model_ref_type
      @virtual_model_ref ? @virtual_model_ref.type : :saved_search
    end

    # returns the appropriate view path
    # TODO: this bakes in some "ordering with a type; is this right place to put this?
    def ret_view_path(type)
      case(type)
       when :system 
        ViewPathFile.new("#{R8::Config[:system_views_dir]}/#{@profile}.#{@view_name}.rtpl")
       when :base 
        ViewPathFile.new("#{R8::Config[:base_views_dir]}/#{@model_name}/#{@profile}.#{@view_name}.rtpl")
       when :meta
        # first see if there is a meta template for specfic profile type; if not look for default;
        path = ret_if_exists(ViewPathFile.new("#{R8::Config[:meta_templates_root]}/#{@model_name}/view.#{@profile}.#{@view_name}.rb"))
        return path if path
        return nil if @profile.to_sym == :default
        ViewPathFile.new("#{R8::Config[:meta_templates_root]}/#{@model_name}/view.default.#{@view_name}.rb")
       when :meta_db
         ViewPathDB.new(virtual_model_ref)
       when :cache 
        # TODO: fix so saved_search not hard coded
        if virtual_model_ref
          if virtual_model_ref_type() == :virtual_object
            ViewPathFile.new("#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.#{virtual_model_ref.view_meta_id}.rtpl")
          else
            ViewPathFile.new("#{R8::Config[:app_cache_root]}/view/saved_search/#{@profile}.#{virtual_model_ref}.rtpl")
          end
        else
          ViewPathFile.new("#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.rtpl")
        end
       when :layout
        # TODO: see if profile is used to qualify
        ViewPathFile.new("#{R8::Config[:app_root_path]}/view/#{@view_name}.rtpl")
       when :css_require
        ViewPathFile.new("#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.css_include.json")
       when :js_require
        ViewPathFile.new("#{R8::Config[:app_cache_root]}/view/#{@model_name}/#{@profile}.#{@view_name}.js_include.json")
       else
        Log.error("call to ret_view_path with no handler for type: #{type}")
        nil
      end
    end

    # returns the appropriate view path if it exists
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

    def view_type(vn=nil)
      ViewTranslations[(vn||@view_name).to_sym]
    end
    ViewTranslations = {
      edit: 'edit',
      quick_edit: 'edit',
      list_edit_in_place: 'edit',
      display: 'display',
      hover: 'display',
      saved_search: 'list',
      list: 'list',
      related_panel: 'list',
      search: 'search'
    }
  end
end
