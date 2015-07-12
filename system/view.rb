require File.expand_path('field.r8', File.dirname(__FILE__))
require File.expand_path('common_mixin', File.dirname(__FILE__))

module R8Tpl
  class ViewR8
    include CommonMixin
    include Utility::I18n
    attr_accessor :obj_name, :tpl_contents, :css_require, :js_require
    attr_reader :user

    def self.create(tpl, view_path)
      all_args = 6.times.inject([]) { |x, _y| x << nil } + [tpl, view_path]
      self.new(*all_args)
    end

    def new_initialize(tpl, view_path)
      @model_name = tpl.model_name
      @view_name = tpl.view_name
      @virtual_model_ref = tpl.virtual_model_ref
      @user = tpl.user
      @profile = @user.current_profile || :default #profile will dictate the specific view to use/generate
      @view_path = view_path

      @form_id = "#{@model_name}-#{@view_name}-form"
      @i18n = get_model_i18n(@model_name, @user)

      # TODO: probably remove
      # if set non null then will not try to find path and pull from file
      @view_meta = nil    #hash defining an instance of a view

      initialize_vars()
    end

    # TODO: need to refactor this signature
    def initialize(model_name, view_name, user, is_saved_search = false, view_meta_hash = nil, opts = {}, *args)
      return new_initialize(*args) unless args.empty?

      # TODO: clean up
      @model_name = model_name
      @saved_search_ref = nil
      @view_name = view_name
      if is_saved_search
        @saved_search_ref = view_name
        @view_name = opts[:view_type] || :list #TODO: should not be hard-wired
      end

      @form_id = "#{@model_name}-#{@view_name}-form"
      @user = user
      @profile = @user.current_profile || :default #profile will dictate the specific view to use/generate
      @i18n = get_model_i18n(model_name, user)

      # if set non null then will not try to find path and pull from file
      @view_meta = view_meta_hash    #hash defining an instance of a view

      initialize_vars()
    end

    def initialize_vars
      @override_meta_path = nil        #path where the overrides for a view should be located

      @js_cache_path = nil             #this is the path to the JS file that will process/render the view
      @tpl_read_path = nil            #this is the path to read the base tpl file that gets compiled from the view_meta

      @tpl_contents = nil	            #This is contents of template
      @css_require = []
      @js_require = []
    end

    def update_cache_for_virtual_object
      case @view_name
        when :edit then render_edit_tpl_cache()
        when :display then render_display_tpl_cache()
        when :list then render_list_tpl_cache()
      end
      ret_existing_view_path(:cache)
    end

    def update_cache_for_saved_search
      render_list_tpl_cache()
      ret_existing_view_path(:cache)
    end

    # updates cache if necssary and returns the path to the cache
    def update_cache?
      unless cache_current?
        case view_type().to_sym
          when :edit
            render_edit_tpl_cache()
            #          add_validation()
          when :display
            render_display_tpl_cache()
          when :list
            render_list_tpl_cache()
          when :search
            render_search_tpl_cache()
          when :dock_display
            render_dock_display_tpl_cache()
        end
      end
      ret_existing_view_path(:cache)
    end

    def render
      if cache_current?
        @tpl_contents = get_view_tpl_cache()
        @css_require = get_css_require_from_cache()
        @js_require = get_js_require_from_cache()
        return nil
      end

      case (view_type())
        when 'edit'
          render_edit_tpl_cache()
          #       add_validation()
        when 'display'
          render_display_tpl_cache()
        when 'list'
          render_list_tpl_cache()
        when 'search'
          render_search_tpl_cache()
        when 'dock_display'
          render_dock_display_tpl_cache()
        end
      self
    end

  def add_to_css_require(css)
    @css_require << css unless @css_require.includes(css)
  end

  def add_to_js_require(js)
    @js_require << js unless @js_require.includes(js)
  end

    private

  # TODO: may move this to utility.r8
  def i18n(*path)
    # TODO: looks like to get to work currently needto strip off first element
    term = path.dup
    term.shift
    XYZ::HashObject.nested_value(@i18n, term)
  end

  # if not set yet, this will grab/set the meta array for given object/viewType
  # TODO: should have extensible definition of viewName (ie: edit,quickEdit,editInline,etc)
  def view_meta
    @view_meta ||= get_view_meta
  end

  def view_path_type
    @view_path ? @view_path.type : :file
  end

  def get_view_meta
    view_path_type() == :db ? get_view_meta__db() : get_view_meta__file()
  end

  def get_view_meta__db
    component = user.create_object_from_id(@view_path.db_id)
    component.get_view_meta(view_type().to_sym, @virtual_model_ref)
  end

  def get_view_meta__file
    # TODO: revisit to work on override possiblities and for profile handling
    # should check for all view locations, direct and override
    # TODO: figure out best way to do PHP style requires/loading of external meta hashes
    path = ret_existing_view_path(:meta)

    if path
      XYZ::Aux.convert_to_hash_symbol_form(eval(IO.read(path)))
      # TODO: check if ok to remove logic wrt to json
    else
     # TODO: figure out handling of overrides
     #      require $GLOBALS['ctrl']->getAppName().'/objects' . $this->objRef->getmodel_name() . '/meta/view.'.$this->profile.'.'.$this->viewName.'.php');
     # require 'some path to require'
     fail XYZ::Error::NotImplemented.new()
    end
  end

 # This will check to see if the TPL view file exists and isnt stale compare to the base TPL and other factors
 def cache_current?
    cache_path = ret_existing_view_path(:cache)
    return nil unless cache_path
    meta_view_path = ret_existing_view_path(view_path_type() == :db ? :meta_db : :meta)
    fail XYZ::Error.new('to generate cache appropriate meta file must exist') unless  meta_view_path
    system_view_path = ret_existing_view_path(:system)
    fail XYZ::Error.new('to generate cache appropriate system file must exist') unless  system_view_path

    if not R8::Config[:dev_mode].nil? or R8::Config[:dev_mode] == false
      cache_edit_time = cache_path.edit_time_as_int()
      meta_view_edit_time = meta_view_path.edit_time_as_int()
      system_view_edit_time = system_view_path.edit_time_as_int()
      cache_edit_time > meta_view_edit_time and cache_edit_time > system_view_edit_time
    else
      nil
    end
  end

  def get_system_rtpl_contents
    IO.read(ret_existing_view_path(:system))
  end

  def get_view_tpl_cache
    IO.read(ret_existing_view_path(:cache))
  end

  def get_css_require_from_cache
    path = ret_existing_view_path(:css_require)
    return nil unless path
    # TODO: collapse Aux and Utils together into whatever it will be called
    XYZ::Aux.convert_to_hash_symbol_form(IO.read(path))
  end

  def get_js_require_from_cache
    path = ret_existing_view_path(:jss_require)
    return nil unless path
    # TODO: collapse Aux and Utils together into whatever it will be called
    XYZ::Aux.convert_to_hash_symbol_form(IO.read(path))
  end

  # This function will generate the TPL cache for a view of type list
  def render_list_tpl_cache
    # TODO: can probably move most of this function to a general function call
    # and re-use between render_view_js_cache and renderViewHTML
    field_handler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new("#{@model_name}/#{@view_name}", @user, :system)
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

    r8TPL.assign(:model_name, @model_name)
    r8TPL.assign(:base_uri, '{%=_app[:base_uri]%}')
    r8TPL.assign(:search_content, '{%=search_content%}')
    r8TPL.assign(:view_name, @view_name)
    # TODO: is this right?
    r8TPL.assign(:th_row_class,  @model_name)
    #    i18n = utils.get_model_i18n(@model_name)

    list_cols = []

    view_meta[:field_list].each do |field_hash|
      field_hash.each do |field_name, field_meta|
        field_meta[:model_name] = @model_name
        field_meta[:name] = field_name

        if @i18n[(field_meta[:name].to_s + '_' + @view_name.to_s).to_sym]
          field_meta[:label] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + '_' + @view_name.to_s + ']%}'
        elsif @i18n[field_meta[:name].to_sym]
          field_meta[:label] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + ']%}'
        else
          field_meta[:label] = field_meta[:name]
        end

        field_meta[:id] = field_meta[:name] if field_meta[:id].nil?
        field_meta[:class] = field_meta[:class]
        field_meta[:content] = field_handler.get_field(view_type(), field_meta, 'tpl')
        field_meta[:width] = (field_meta[:width].nil? ? '' : 'width="' + field_meta[:width] + '"')

        # might move later, putting sorting code here
        # TODO: look for better way to do find fields taht should not have sorting
        if (field_hash.values.first || {})[:type] == 'actions_basic'
          field_meta[:sort_call] = ''
          field_meta[:sort_class] = ''
        else
          field_meta[:sort_call] = "onclick=\"R8.Search.sort('{%=search_context%}','#{field_name}','{%=#{field_name}_order%}');\""
          field_meta[:sort_class] = "{%=#{field_name}_order_class%}"
        end
        list_cols << field_meta
      end
    end

    model_name = @model_name
    # build & assign the foreach header for the JS template
    r8TPL.assign(:foreach_header_content, '{%for ' + model_name.to_s + ' in ' + model_name.to_s + '_list%}')
    r8TPL.assign(:tr_class, '{%=' + obj_name.to_s + '[:class]%}')
    r8TPL.assign(:cols, list_cols)

    # this might be temp until figuring out if template literals are possible
    r8TPL.assign(:current_start_literal, '{%=current_start%}')
    r8TPL.assign(:search_context_literal, '{%=search_context%}')
    r8TPL.assign(:list_start_prev_literal, '{%=list_start_prev%}')
    r8TPL.assign(:list_start_next_literal, '{%=list_start_next%}')
    r8TPL.assign(:iterator_var, '{%=' + model_name.to_s + '%}')
    r8TPL.assign(:end_tag, '{%end%}')

    @tpl_contents = r8TPL.render(get_system_rtpl_contents())
    fwrite()
  end

  # This function will return the path for the given viewName (detail,edit,list,etc)
  # If the template/cache/path do not exist or is stale it will generate a new one

  # This will add js calls to add each field to form validation
  def add_validation
    field_handler = FieldR8.new(self)

    (view_meta[:field_groups] || []).each do |group_num, _group_hash|
      view_meta[:field_sets][group_num][:fields].each do |_field_num, field_hash|
        next if (fieldArray.length == 0)

        field_hash.each do |field_name, field_meta|
          field_meta[:field_name] = field_name
          unless (field_meta[:id].nil?) then field_meta[:id] = field_meta[:field_name] end
          field_meta[:model_name] = @model_name
          field_handler.addValidation(@form_id, field_meta)
        end
      end
    end
  end

  # This function will generate the TPL cache for a view of type edit
  def render_edit_tpl_cache
    # TODO: can probably move most of this function to a general function call
    # and re-use between render_view_js_cache and renderViewHTML
    field_handler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new("#{@model_name}/#{@view_name}", @user, :system)
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

    #    i18n = utils.get_model_i18n(@model_name)
    r8TPL.assign(:formId, @form_id)
    r8TPL.assign(:formAction, view_meta[:action])

    td_label_class = (view_meta[:td_label_class].nil? ? 'label' : view_meta[:td_label_class])
    td_field_class = (view_meta[:td_field_class].nil? ? 'field' : view_meta[:td_field_class])

    # add any form hidden fields
    hidden_fields = []
    (view_meta[:hidden_fields] || []).each do |hfield_hash|
      hfield_hash.each do |field_name, field_meta|
        field_meta[:name] = field_name.to_s
        field_meta[:id] ||= field_meta[:name]
        field_meta[:value] ||= "{%=#{@model_name}[:#{field_name}]%}"
        hidden_fields << field_meta
      end
    end
    r8TPL.assign(:h_field_list, hidden_fields)

    rows = []
    group_num = 0
    (view_meta[:field_groups] || []).each do |group_hash|
      row_count = 0
      display_labels = group_hash[:display_labels]
      num_cols = group_hash[:num_cols].to_i
      col_index = 0
      field_num = 0
      rows[row_count] = {}
      rows[row_count][:cols] = []

      group_hash[:fields].each do |field_hash|
        field_num += 1
        rows[row_count][:row_id] = 'g' + group_num.to_s + '-r' + row_count.to_s
        # if size is 0 then its a blank spot in the form
        if field_hash.length == 0
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] = td_label_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r' + row_count.to_s + '-c' + col_index.to_s + '-label'
          col_index += 1
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] =  td_field_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r' + row_count.to_s + '-c' + col_index.to_s + '-field'
        else
          field_hash.each do |field_name, field_meta|
            field_meta[:name] = field_name.to_sym
            field_meta[:id] ||= field_meta[:name]
            field_meta[:model_name] = @model_name
            # do label
            rows[row_count][:cols][col_index] = {}

            if display_labels
              if @i18n[(field_meta[:name].to_s + '_' + @view_name.to_s).to_sym]
                rows[row_count][:cols][col_index][:content] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + '_' + @view_name.to_s + ']%}'
              elsif @i18n[field_meta[:name].to_sym]
                rows[row_count][:cols][col_index][:content] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + ']%}'
              else
                rows[row_count][:cols][col_index][:content] = field_meta[:name]
              end
            else
              rows[row_count][:cols][col_index][:content] = '&nbsp;'
            end

            rows[row_count][:cols][col_index][:class] = td_label_class
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s + '-label'
            col_index += 1
            rows[row_count][:cols][col_index] = {}
            # do field
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s + '-field'
            rows[row_count][:cols][col_index][:content] = field_handler.get_field(view_type(), field_meta, 'tpl')
            rows[row_count][:cols][col_index][:class] = td_field_class
          end
        end
        # if remainder is 0 then its time to start rendering the next row, increment row, reset col
        if (field_num.remainder(num_cols) == 0) then
          row_count += 1
          col_index = 0
          rows[row_count] = {}
          rows[row_count][:cols] = []
        else
          col_index += 1
        end
        # end of field interation
      end
      # end of group interation
      group_num += 1
    end
    r8TPL.assign(:rows, rows)

    @tpl_contents = r8TPL.render(get_system_rtpl_contents())
    fwrite()
  end

  # This function will generate the TPL cache for a view of type display
  def render_display_tpl_cache
    # TODO: can probably move most of this function to a general function call
    # and re-use between render_view_js_cache and renderViewHTML
    field_handler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new("#{@model_name}/#{@view_name}", @user, :system)
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

    #    i18n = utils.get_model_i18n(@model_name)
    r8TPL.assign(:formId, @form_id)
    r8TPL.assign(:formAction, view_meta[:action])
    r8TPL.assign(:editId, "{%=#{@model_name}[:id]%}")

    td_label_class = (view_meta[:td_label_class].nil? ? 'label' : view_meta[:td_label_class])
    td_field_class = (view_meta[:td_field_class].nil? ? 'field' : view_meta[:td_field_class])

    # add any form hidden fields
    hidden_fields = []
    (view_meta[:hidden_fields] || []).each do |hfield_hash|
      hfield_hash.each do |field_name, field_meta|
        field_meta[:name] = field_name.to_s
        field_meta[:id] ||= field_meta[:name]
        field_meta[:value] ||= "{%=#{@model_name}[:#{field_name}]%}"
        hidden_fields << field_meta
      end
    end
    r8TPL.assign(:h_field_list, hidden_fields)

    rows = []
    group_num = 0
    (view_meta[:field_groups] || []).each do |group_hash|
      row_count = 0
      display_labels = group_hash[:display_labels]
      num_cols = group_hash[:num_cols].to_i
      col_index = 0
      field_num = 0
      rows[row_count] = {}
      rows[row_count][:cols] = []

      group_hash[:fields].each do |field_hash|
        field_num += 1
        rows[row_count][:row_id] = 'g' + group_num.to_s + '-r' + row_count.to_s
        # if size is 0 then its a blank spot in the form
        if (field_hash.length == 0) then
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] = td_label_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r' + row_count.to_s + '-c' + col_index.to_s + '-label'
          col_index += 1
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] =  td_field_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r' + row_count.to_s + '-c' + col_index.to_s + '-field'
        else
          field_hash.each do |field_name, field_meta|
            field_meta[:name] = field_name.to_sym
            if (field_meta[:id].nil?) then field_meta[:id] = field_meta[:name] end
            field_meta[:model_name] = @model_name

            rows[row_count][:cols][col_index] = {}

            # do label
            if display_labels
              if @i18n[(field_meta[:name].to_s + '_' + @view_name.to_s).to_sym]
                rows[row_count][:cols][col_index][:content] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + '_' + @view_name.to_s + ']%}'
              elsif @i18n[field_meta[:name].to_sym]
                rows[row_count][:cols][col_index][:content] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + ']%}'
              else
                rows[row_count][:cols][col_index][:content] = field_meta[:name]
              end
            else
              rows[row_count][:cols][col_index][:content] = '&nbsp;'
            end

            rows[row_count][:cols][col_index][:class] = td_label_class
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s + '-label'
            col_index += 1
            rows[row_count][:cols][col_index] = {}
            # do field
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s + '-field'
            rows[row_count][:cols][col_index][:content] = field_handler.get_field(view_type(), field_meta, 'tpl')
            rows[row_count][:cols][col_index][:class] = td_field_class
          end
        end
        # if remainder is 0 then its time to start rendering the next row, increment row, reset col
        if (field_num.remainder(num_cols) == 0) then
          row_count += 1
          col_index = 0
          rows[row_count] = {}
          rows[row_count][:cols] = []
        else
          col_index += 1
        end
        # end of field interation
      end
      # end of group interation
      group_num += 1
    end
    r8TPL.assign(:rows, rows)

    @tpl_contents = r8TPL.render(get_system_rtpl_contents())
    fwrite()
  end

  # writes template, js_include and css_include
  def fwrite
    files = {
     ret_view_path(:cache) => @tpl_contents,
     ret_view_path(:css_require) => @css_require ? JSON.pretty_generate(@css_require) : nil,
     ret_view_path(:js_require) => @js_require ? JSON.pretty_generate(@js_require) : nil
    }

    files.each do |path, content|
      next unless content
      FileUtils.mkdir_p(File.dirname(path)) unless File.exist?(File.dirname(path))
      File.open(path, 'w') { |fhandle| fhandle.write(content) }
    end
  end

  def render_search_tpl_cache
    field_handler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new("#{@model_name}/#{@view_name}", @user, :system)
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

    #    i18n = utils.get_model_i18n(@model_name)
    r8TPL.assign(:model_name_literal, '{%=model_name%}')
    r8TPL.assign(:base_uri, '{%=_app[:base_uri]%}')
    r8TPL.assign(:formId, @form_id)
    r8TPL.assign(:formAction, view_meta[:action])
    r8TPL.assign(:search_id_literal, '{%=search_id%}')
    r8TPL.assign(:search_context_literal, '{%=search_context%}')

    r8TPL.assign(:current_start_literal, '{%=current_start%}')
    r8TPL.assign(:search_cond_literal, '{%if num_saved_searches > 0%}')
    r8TPL.assign(:end_literal, '{%end%}')

    # TODO: temp hack until more fully implemented select/dropdown fields
    r8TPL.assign(:saved_search_list_dropdown, '
      {%for saved_search in _saved_search_list%}
        <option value="{%=saved_search[:id]%}" {%=saved_search[:selected]%}>{%=saved_search[:display_name]%}</option>
      {%end%}
    ')

    td_label_class = (view_meta[:td_label_class].nil? ? 'label' : view_meta[:td_label_class])
    td_field_class = (view_meta[:td_field_class].nil? ? 'field' : view_meta[:td_field_class])

    # add any form hidden fields
    hidden_fields = []
    (view_meta[:hidden_fields] || []).each do |hfield_hash|
      hfield_hash.each do |field_name, field_meta|
        field_meta[:name] = field_name.to_s
        field_meta[:id] ||= field_meta[:name]
        field_meta[:value] ||= "{%=#{@model_name}[:#{field_name}]%}"
        hidden_fields << field_meta
      end
    end
    r8TPL.assign(:h_field_list, hidden_fields)

    rows = []
    group_num = 0
    (view_meta[:field_groups] || []).each do |group_hash|
      row_count = 0
      display_labels = group_hash[:display_labels]
      num_cols = group_hash[:num_cols].to_i
      col_index = 0
      field_num = 0
      rows[row_count] = {}
      rows[row_count][:cols] = []

      group_hash[:fields].each do |field_hash|
        field_num += 1
        rows[row_count][:row_id] = 'g' + group_num.to_s + '-r' + row_count.to_s
        # if size is 0 then its a blank spot in the form
        if field_hash.length == 0
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] = td_label_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r' + row_count.to_s + '-c' + col_index.to_s + '-label'
          col_index += 1
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] =  td_field_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r' + row_count.to_s + '-c' + col_index.to_s + '-field'
        else
          field_hash.each do |field_name, field_meta|
            field_meta[:name] = field_name.to_sym
            field_meta[:id] ||= field_meta[:name]
            field_meta[:model_name] = @model_name
            # do label
            rows[row_count][:cols][col_index] = {}

            if display_labels
              if @i18n[(field_meta[:name].to_s + '_' + @view_name.to_s).to_sym]
                rows[row_count][:cols][col_index][:content] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + '_' + @view_name.to_s + ']%}'
              elsif @i18n[field_meta[:name].to_sym]
                rows[row_count][:cols][col_index][:content] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + ']%}'
              else
                rows[row_count][:cols][col_index][:content] = field_meta[:name]
              end
            else
              rows[row_count][:cols][col_index][:content] = '&nbsp;'
            end

            rows[row_count][:cols][col_index][:class] = td_label_class
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s + '-label'
            col_index += 1
            rows[row_count][:cols][col_index] = {}
            # do field
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s + '-field'
            rows[row_count][:cols][col_index][:content] = field_handler.get_field(view_type(), field_meta, 'rtpl')
            rows[row_count][:cols][col_index][:class] = td_field_class
          end
        end
        # if remainder is 0 then its time to start rendering the next row, increment row, reset col
        if (field_num.remainder(num_cols) == 0) then
          row_count += 1
          col_index = 0
          rows[row_count] = {}
          rows[row_count][:cols] = []
        else
          col_index += 1
        end
        # end of field interation
      end
      # end of group interation
      group_num += 1
    end
    r8TPL.assign(:rows, rows)

    @tpl_contents = r8TPL.render(get_system_rtpl_contents())
    fwrite()
  end

  #------------------------------------------------------------------------------
  #---------------This will lay groundwork for next setup of views/tpls----------
  #------------------------------------------------------------------------------
  def render_dock_display_tpl_cache
    field_handler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new("#{@model_name}/#{@view_name}", @user, :system)
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

    #    i18n = utils.get_model_i18n(@model_name)
    r8TPL.assign(:formId, @form_id)
    r8TPL.assign(:formAction, view_meta[:action])
    r8TPL.assign(:editId, "{%=#{@model_name}[:id]%}")

    td_label_class = (view_meta[:td_label_class].nil? ? 'label' : view_meta[:td_label_class])
    td_field_class = (view_meta[:td_field_class].nil? ? 'field' : view_meta[:td_field_class])

    # add any form hidden fields
    hidden_fields = []
    (view_meta[:hidden_fields] || []).each do |hfield_hash|
      hfield_hash.each do |field_name, field_meta|
        field_meta[:name] = field_name.to_s
        field_meta[:id] ||= field_meta[:name]
        field_meta[:value] ||= "{%=#{@model_name}[:#{field_name}]%}"
        hidden_fields << field_meta
      end
    end
    r8TPL.assign(:h_field_list, hidden_fields)

    rows = []
    group_num = 0
    (view_meta[:field_groups] || []).each do |group_hash|
      row_count = 0
      display_labels = group_hash[:display_labels]
      num_cols = group_hash[:num_cols].to_i
      col_index = 0
      field_num = 0
      rows[row_count] = {}
      rows[row_count][:cols] = []

      group_hash[:fields].each do |field_hash|
        field_num += 1
        rows[row_count][:row_id] = 'g' + group_num.to_s + '-r' + row_count.to_s
        # if size is 0 then its a blank spot in the form
        if (field_hash.length == 0) then
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] = td_label_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r' + row_count.to_s + '-c' + col_index.to_s + '-label'
          col_index += 1
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] =  td_field_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r' + row_count.to_s + '-c' + col_index.to_s + '-field'
        else
          field_hash.each do |field_name, field_meta|
            field_meta[:name] = field_name.to_sym
            if (field_meta[:id].nil?) then field_meta[:id] = field_meta[:name] end
            field_meta[:model_name] = @model_name

            rows[row_count][:cols][col_index] = {}

            # do label
            if display_labels
              if @i18n[(field_meta[:name].to_s + '_' + @view_name.to_s).to_sym]
                rows[row_count][:cols][col_index][:content] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + '_' + @view_name.to_s + ']%}'
              elsif @i18n[field_meta[:name].to_sym]
                rows[row_count][:cols][col_index][:content] = '{%=_' + @model_name.to_s + '[:i18n][:' + field_meta[:name].to_s + ']%}'
              else
                rows[row_count][:cols][col_index][:content] = field_meta[:name]
              end
            else
              rows[row_count][:cols][col_index][:content] = '&nbsp;'
            end

            rows[row_count][:cols][col_index][:class] = td_label_class
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s + '-label'
            col_index += 1
            rows[row_count][:cols][col_index] = {}
            # do field
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s + '-field'
            rows[row_count][:cols][col_index][:content] = field_handler.get_field(view_type(), field_meta, 'tpl')
            rows[row_count][:cols][col_index][:class] = td_field_class
          end
        end
        # if remainder is 0 then its time to start rendering the next row, increment row, reset col
        if (field_num.remainder(num_cols) == 0) then
          row_count += 1
          col_index = 0
          rows[row_count] = {}
          rows[row_count][:cols] = []
        else
          col_index += 1
        end
        # end of field interation
      end
      # end of group interation
      group_num += 1
    end
    r8TPL.assign(:rows, rows)

    @tpl_contents = r8TPL.render(get_system_rtpl_contents())
    fwrite()
  end
  #------------------------------------------------------------------------------

  # This will return the path for the JS cache file
  # TODO: revisit once randomizer js template naming is going a-la smarty caches
  def get_view_js_cache_path
    if @js_cache_path.nil?
      @js_cache_path = "#{R8::Config[:js_file_write_path]}/#{@profile}.#{@view_name}.js"
    end
    @js_cache_path
  end

  # This will check to see if the JS form file exists and isnt stale compare to the TPL and other factors
  # TODO: make sure to return and rewrite after adding util/generic file access function
  # ex: should transparently check for either local file, or AWS, CDN, etc
  def viewJSCurrent
    if (File.exist?(get_view_js_cache_path())) then
      # TODO: make sure to return and rewrite after adding util/generic file access function
      # ex: should transparently check for either local file, or AWS, CDN, etc
      jsCacheEditTime = File.mtime(get_view_js_cache_path()).to_i
      tplCacheEditTime = File.mtime(view_tpl_cache_path()).to_i
      # adding this since rendering logic is in this file, might update it w/o changing template,
      # jsTpl should then be updated to reflect changes
      # TODO: switch this when functions moved to js compile class
      #      templateR8EditTime = File.mtime(getcwd()."/system/template.r8.php");
      templateR8EditTime = File.mtime(Dir.pwd + '/template.rb')
      if (jsCacheEditTime < templateR8EditTime || jsCacheEditTime < tplCacheEditTime) then
        return false
      else
        return true
      end
    else
      return false
    end
  end

  # This function will generate the js cache for the form
  def render_view_js_cache
    # TODO: nothing here yet, must revisit when deciding to create master field class for a profile
    # that can render individual fields on the fly in the browser
  end
end
end
