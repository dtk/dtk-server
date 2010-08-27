require File.expand_path('field.r8.rb', File.dirname(__FILE__))
require File.expand_path('common_mixin.r8', File.dirname(__FILE__))
module R8Tpl
  class ViewR8
    include CommonMixin
    attr_accessor :obj_name, :tpl_contents, :css_require, :js_require
    Views = Hash.new
    def initialize(model_name,view_name,user)
      @model_name = model_name	  #object type (a symbol)
      @view_name = view_name              #viewName can be either edit,detail,list,etc
      @form_id = "#{@model_name}-#{@view_name}-form"
      @user = user
      @profile = @user.current_profile || :default #profile will dictate the specific view to use/generate
      @i18n_hash = load_i18n_hash(model_name)

      @view_meta = nil    #hash defining an instance of a view

      @override_meta_path = nil        #path where the overrides for a view should be located

      @js_cache_path = nil             #this is the path to the JS file that will process/render the view
      @tpl_read_path = nil            #this is the path to read the base tpl file that gets compiled from the view_meta

      @tpl_contents = nil	            #This is contents of template
      @css_require = []
      @js_require = []
    end

    def load_i18n_hash(model_name)
      file_name = "#{R8::Config[:i18n_root]}/#{model_name}/#{R8::Config[:default_language]}.rb"
      return eval(IO.read(file_name)) if File.exists?(file_name)
      file_name = "#{R8::Config[:i18n_root]}/#{R8::Config[:default_language]}.rb"
      return eval(IO.read(file_name)) if File.exists?(file_name)
      Hash.new
    end

    def render()

      if cache_current?
        @tpl_contents = get_view_tpl_cache()
        @css_require = get_css_require_from_cache()
        @js_require = get_js_require_from_cache()
        return nil
      end

      case (view_type())
      when "edit"
        render_edit_tpl_cache() 
        #       add_validation()
      when "display"
        render_display_tpl_cache()
      when "list"
        render_list_tpl_cache() 
      end
      self
    end
  
  def add_to_css_require(css)
    @css_require << css unless @css_require.includes(css)
  end

  def add_to_js_require(js)
    @js_require << js unless @js_require.includes(js)
  end

  #updates cache if necssary and returns the path to the cache
  def update_cache?()
    unless cache_current?
      case view_type().to_sym
        when :edit
          render_edit_tpl_cache() 
#          add_validation()
        when :display
          render_display_tpl_cache() 
        when :list
          render_list_tpl_cache() 
      end
    end
     ret_existing_view_path(:cache)
  end
 private

  def i18n(*path)
    XYZ::HashObject.nested_value(@i18n_hash,path)
  end

  ViewTranslations = {
    :edit => 'edit',
    :quick_edit => 'edit',
    :list_edit_in_place => 'edit',
    :display => 'display',
    :hover => 'display',
    :list => 'list',
    :related_panel => 'list'
  }

  def view_type()
    #TBD: error if @view_name is not set
    ViewTranslations[@view_name.to_sym]
  end
  #if not set yet, this will grab/set the meta array for given object/viewType
  # TODO: should have extensible definition of viewName (ie: edit,quickEdit,editInline,etc)


  def view_meta()
    @view_meta ||= get_view_meta
  end
  def get_view_meta()
    Views[@model_name] ||= {}
    Views[@model_name][@profile] ||= {}
    Views[@model_name][@profile][@view_name] ||= {}

    #TODO: revisit to work on override possiblities and for profile handling
    #should check for all view locations, direct and override
    #TODO: figure out best way to do PHP style requires/loading of external meta hashes
    path = ret_existing_view_path(:meta)
    if path
      hash = XYZ::Aux.convert_to_hash_symbol_form(eval(IO.read(path)))
      Views[@model_name][@profile][@view_name] = hash
      #TODO check if ok to remove logic wrt to json
    else
      #TODO: figure out handling of overrides
      #      require $GLOBALS['ctrl']->getAppName().'/objects' . $this->objRef->getmodel_name() . '/meta/view.'.$this->profile.'.'.$this->viewName.'.php');
      # require 'some path to require'
     raise XYZ::ErrorNotImplemented.new()
    end
    Views[@model_name][@profile][@view_name]
  end


  # This will check to see if the TPL view file exists and isnt stale compare to the base TPL and other factors
  def cache_current?()
    cache_path = ret_existing_view_path(:cache)
    return nil unless cache_path
    meta_view_path = ret_existing_view_path(:meta)
    raise XYZ::Error.new("to generate cache appropriate meta file must exist") unless  meta_view_path
    system_view_path = ret_existing_view_path(:system)
    raise XYZ::Error.new("to generate cache appropriate system file must exist") unless  system_view_path

    #TBD: ask Nate about intended semantics; modified because error if file does not exist, but clause executed
    if not R8::Config[:dev_mode].nil? or R8::Config[:dev_mode] == false
      cache_edit_time = File.mtime(cache_path).to_i
      meta_view_edit_time = File.mtime(meta_view_path).to_i
      system_view_edit_time = File.mtime(system_view_path).to_i
      cache_edit_time > meta_view_edit_time and  cache_edit_time > system_view_edit_time
    else
      nil #TODO: should this be true or nil?
    end
  end
=begin 
TODO: remove after making sure new logic is right
OLD
      #adding this since rendering logic is in this file, might update it w/o changing template,
      #jsTpl should then be updated to reflect changes
      #TODO: switch this when functions moved to js compile class
      # TBD put pick in only if template.r8.rb prefixed by app_name app_name = 'formtests' #TBD: stubbed
      #   templateR8EditTime = File.mtime(R8::Config[:app_root_path] + #{R8::Config[:application_name]} + "/template.r8.rb").to_i
      #TBD: below is stub
      return false#TBD: below is wrong so executing here

      template_r8_edit_time = File.mtime("#{SYSTEM_DIR}/r8/template.r8.rb").to_i
      if(tpl_cache_edit_time < template_r8_edit_time || tpl_cache_edit_time < view_meta_edit_time || tpl_cache_edit_time < view_tpl_edit_time) then
        return false
      else
        return true
      end
    else
      return false
    end
  end
=end

  def get_system_rtpl_contents()
    IO.read(ret_existing_view_path(:system))
  end

  def get_view_tpl_cache()
    IO.read(ret_existing_view_path(:cache))
  end

  def get_css_require_from_cache()
    path = ret_existing_view_path(:css_require)
    return nil unless path
    XYZ::Aux.convert_to_hash_symbol_form(IO.read(path))
  end

  def get_js_require_from_cache()
    path = ret_existing_view_path(:jss_require)
    return nil unless path
    XYZ::Aux.convert_to_hash_symbol_form(IO.read(path))
  end

  # This function will generate the TPL cache for a view of type list
  def render_list_tpl_cache()
#TODO: can probably move most of this function to a general function call
#and re-use between renderViewJSCache and renderViewHTML
    field_handler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new("#{@model_name}/#{@view_name}",@user,:system)
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

    r8TPL.assign(:model_name, @model_name)
    r8TPL.assign(:view_name, @view_name)
    #TODO: is this right?
    r8TPL.assign(:th_row_class,  @model_name)
#    i18n = utils.get_model_i18n(@model_name)

    list_cols = []
    view_meta[:field_list].each do |field_hash|
      field_hash.each do |field_name,field_meta|
        field_meta[:model_name] = @model_name
        field_meta[:name] = field_name
        field_meta[:label] = i18n(:default_list,field_meta[:name]) || field_meta[:name]
        field_meta[:id] = field_meta[:name] if field_meta[:id].nil?
        field_meta[:class] = field_meta[:class]
        field_meta[:content] = field_handler.get_field(view_type(), field_meta, 'tpl')
        field_meta[:width] = (field_meta[:width].nil? ? '' : 'width="'+field_meta[:width]+'"')
        list_cols << field_meta
      end
    end

    model_name = @model_name
    #build & assign the foreach header for the JS template
    r8TPL.assign(:foreach_header_content,'{%for '+model_name.to_s+' in '+ model_name.to_s+'_list%}')
    r8TPL.assign(:tr_class, '{%='+obj_name.to_s+'[:class]%}')
    r8TPL.assign(:cols, list_cols)

    #this might be temp until figuring out if template literals are possible
    r8TPL.assign(:list_start_prev_var, '{%=list_start_prev%}')
    r8TPL.assign(:list_start_next_var, '{%=list_start_next%}')
    r8TPL.assign(:iterator_var, '{%='+model_name.to_s+'%}')
    r8TPL.assign(:end_tag, '{%end%}')

    @tpl_contents = r8TPL.render(get_system_rtpl_contents())
    fwrite()
  end

  # This function will return the path for the given viewName (detail,edit,list,etc)
  # If the template/cache/path do not exist or is stale it will generate a new one

  # This will add js calls to add each field to form validation
  def add_validation()
    field_handler = FieldR8.new(self)

    (view_meta[:field_groups]||[]).each do |group_num,group_hash|
      view_meta[:field_sets][group_num][:fields].each do |field_num,field_hash|
        next if(fieldArray.length == 0)

        field_hash.each do |field_name,field_meta|
          field_meta[:field_name] = field_name
          if(!field_meta[:id].nil?) then field_meta[:id] = field_meta[:field_name] end
          field_meta[:model_name] = @model_name
          field_handler.addValidation(@form_id, field_meta)
        end
      end
    end
  end


  # This function will generate the TPL cache for a view of type edit
  def render_edit_tpl_cache()
#TODO: can probably move most of this function to a general function call
#and re-use between renderViewJSCache and renderViewHTML
    field_handler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new("#{@model_name}/#{@view_name}",@user,:system)
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

#    i18n = utils.get_model_i18n(@model_name)
    r8TPL.assign(:formId, @form_id)
    r8TPL.assign(:formAction, view_meta[:action])

    td_label_class = (view_meta[:td_label_class].nil? ? 'label' : view_meta[:td_label_class])
    td_field_class = (view_meta[:td_field_class].nil? ? 'field' : view_meta[:td_field_class])

    #add any form hidden fields
    hidden_fields = []
    (view_meta[:hidden_fields]||[]).each do |hfield_hash|
      hfield_hash.each do |field_name,field_meta|
        field_meta[:name] = field_name.to_s
        field_meta[:id] ||= field_meta[:name]
        field_meta[:value] ||= "{%=#{@model_name}[:#{field_name}]%}"
        hidden_fields << field_meta
      end
    end
    r8TPL.assign(:h_field_list, hidden_fields)

    rows = Array.new
    group_num = 0
    (view_meta[:field_groups]||[]).each do |group_hash|
      row_count = 0
      display_labels = group_hash[:display_labels]
      num_cols = group_hash[:num_cols].to_i
      col_index = 0
      field_num = 0
      rows[row_count] = Hash.new
      rows[row_count][:cols] = Array.new

      group_hash[:fields].each do |field_hash|
        field_num +=1
        rows[row_count][:row_id] = 'g'+group_num.to_s+'-r'+row_count.to_s
        #if size is 0 then its a blank spot in the form
        if field_hash.length == 0
          rows[row_count][:cols][col_index] = Hash.new
          rows[row_count][:cols][col_index][:class] = td_label_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r'+row_count.to_s+'-c'+col_index.to_s+'-label'
          col_index+=1
          rows[row_count][:cols][col_index] = Hash.new
          rows[row_count][:cols][col_index][:class] =  td_field_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r'+row_count.to_s+'-c'+col_index.to_s+'-field'
        else
          field_hash.each do |field_name,field_meta|
            field_meta[:name] = field_name.to_sym
            field_meta[:id] ||= field_meta[:name] 
            field_meta[:model_name] = @model_name
            #do label
            rows[row_count][:cols][col_index] = Hash.new
            rows[row_count][:cols][col_index][:content] = display_labels ? (i18n(:default_edit,field_meta[:name].to_sym) || field_meta[:name]) : '&nbsp;'
            rows[row_count][:cols][col_index][:class] = td_label_class
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s+"-label"
            col_index+=1
            rows[row_count][:cols][col_index] = Hash.new
            #do field
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s+"-field"
            rows[row_count][:cols][col_index][:content] = field_handler.get_field(view_type(), field_meta, 'tpl')
            rows[row_count][:cols][col_index][:class] = td_field_class
          end
        end
        #if remainder is 0 then its time to start rendering the next row, increment row, reset col
        if(field_num.remainder(num_cols) == 0) then
          row_count+=1
          col_index = 0
          rows[row_count] = {}
          rows[row_count][:cols] = []
        else 
          col_index+=1
        end
        #end of field interation
      end
      #end of group interation
      group_num +=1
    end
    r8TPL.assign(:rows, rows)

    @tpl_contents = r8TPL.render(get_system_rtpl_contents())
    fwrite()
  end

  # This function will generate the TPL cache for a view of type display
  def render_display_tpl_cache()
#TODO: can probably move most of this function to a general function call
#and re-use between renderViewJSCache and renderViewHTML
    field_handler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new("#{@model_name}/#{@view_name}",@user,:system)
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

#    i18n = utils.get_model_i18n(@model_name)
    r8TPL.assign(:formId, @form_id)
    r8TPL.assign(:formAction, view_meta[:action])

    td_label_class = (view_meta[:td_label_class].nil? ? 'label' : view_meta[:td_label_class])
    td_field_class = (view_meta[:td_field_class].nil? ? 'field' : view_meta[:td_field_class])

    #add any form hidden fields
    hidden_fields = []
    (view_meta[:hidden_fields]||[]).each do |hfield_hash|
      hfield_hash.each do |field_name,field_meta|
        field_meta[:name] = field_name.to_s
        if(field_meta[:id].nil?) then field_meta[:id] = field_meta[:name] end
        hidden_fields << field_meta
      end
    end
    r8TPL.assign(:h_field_list, hidden_fields)

    rows = []
    group_num = 0
    (view_meta[:field_groups]||[]).each do |group_hash|
      row_count = 0
      display_labels = group_hash[:display_labels]
      num_cols = group_hash[:num_cols].to_i
      col_index = 0
      field_num = 0
      rows[row_count] = {}
      rows[row_count][:cols] = []

      group_hash[:fields].each do |field_hash|
        field_num +=1
        rows[row_count][:row_id] = 'g'+group_num.to_s+'-r'+row_count.to_s
        #if size is 0 then its a blank spot in the form
        if(field_hash.length == 0) then
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] = td_label_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r'+row_count.to_s+'-c'+col_index.to_s+'-label'
          col_index+=1
          rows[row_count][:cols][col_index] = {}
          rows[row_count][:cols][col_index][:class] =  td_field_class
          rows[row_count][:cols][col_index][:content] = '&amp;nbsp;'
          rows[row_count][:cols][col_index][:col_id] = 'r'+row_count.to_s+'-c'+col_index.to_s+'-field'
        else
          field_hash.each do |field_name,field_meta|
            field_meta[:name] = field_name.to_sym
            if(field_meta[:id].nil?) then field_meta[:id] = field_meta[:name] end
            field_meta[:model_name] = @model_name
            #do label
            rows[row_count][:cols][col_index] = {}
            if(display_labels) then
              rows[row_count][:cols][col_index][:content] = ((!i18n(:default_edit,field_meta[:name].to_sym).nil?) ? i18n(:default_edit,field_meta[:name].to_sym) : field_meta[:name])
            else
              rows[row_count][:cols][col_index][:content] = '&nbsp;'
            end
            rows[row_count][:cols][col_index][:class] = td_label_class
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s+"-label"
            col_index+=1
            rows[row_count][:cols][col_index] = {}
            #do field
            rows[row_count][:cols][col_index][:col_id] = field_meta[:name].to_s+"-field"
            rows[row_count][:cols][col_index][:content] = field_handler.get_field(view_type(), field_meta, 'tpl')
            rows[row_count][:cols][col_index][:class] = td_field_class
          end
        end
        #if remainder is 0 then its time to start rendering the next row, increment row, reset col
        if(field_num.remainder(num_cols) == 0) then
          row_count+=1
          col_index = 0
          rows[row_count] = {}
          rows[row_count][:cols] = []
        else 
          col_index+=1
        end
        #end of field interation
      end
      #end of group interation
      group_num +=1
    end
    r8TPL.assign(:rows, rows)

    @tpl_contents = r8TPL.render(get_system_rtpl_contents())
    fwrite()
  end

  #writes template, js_include and css_include
  def fwrite()
    files = {
     ret_view_path(:cache) => @tpl_contents,
     ret_view_path(:css_require) => @css_require ? JSON.pretty_generate(@css_require) : nil,
     ret_view_path(:js_require) => @js_require ? JSON.pretty_generate(@js_require) : nil
    }

    files.each do |path, content| 
      if content
        FileUtils.mkdir_p(File.dirname(path)) unless File.exists?(File.dirname(path))
        File.open(path, 'w') {|fhandle|fhandle.write(content)}
      end
    end
  end

  # This will return the path for the JS cache file
#TODO: revisit once randomizer js template naming is going a-la smarty caches
  def getViewJSCachePath()
    if @js_cache_path.nil?
      @js_cache_path = "#{R8::Config[:js_file_write_path]}/#{@profile}.#{@view_name}.js"
    end
    return @js_cache_path
  end

  # This will check to see if the JS form file exists and isnt stale compare to the TPL and other factors
#TODO: make sure to return and rewrite after adding util/generic file access function
#ex: should transparently check for either local file, or AWS, CDN, etc
  def viewJSCurrent()
    if(File.exists?(getViewJSCachePath())) then
#TODO: make sure to return and rewrite after adding util/generic file access function
#ex: should transparently check for either local file, or AWS, CDN, etc
      jsCacheEditTime = File.mtime(getViewJSCachePath()).to_i
      tplCacheEditTime = File.mtime(view_tpl_cache_path()).to_i
      #adding this since rendering logic is in this file, might update it w/o changing template,
      #jsTpl should then be updated to reflect changes
#TODO: switch this when functions moved to js compile class
#      templateR8EditTime = File.mtime(getcwd()."/system/template.r8.php");
      templateR8EditTime = File.mtime(Dir.pwd+"/template.r8.rb")
      if(jsCacheEditTime < templateR8EditTime || jsCacheEditTime < tplCacheEditTime) then
        return false
      else
        return true
      end
    else
      return false
    end
  end

  # This function will generate the js cache for the form
  def renderViewJSCache()
  #TODO: nothing here yet, must revisit when deciding to create master field class for a profile
  #that can render individual fields on the fly in the browser
  end

end
end
