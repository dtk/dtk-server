require File.expand_path('field.r8.rb', File.dirname(__FILE__))

class ViewR8
  attr_accessor :obj_name, :tpl_contents, :css_require, :js_require

  def initialize(obj_name,i18n,profile=nil)
    @view_meta = nil               #hash defining an instance of a view
    @obj_name = obj_name	  #object type (a symbol)
    @i18n_hash = i18n
    # view_meta_path()            #path where the base view meta data should be located
    @override_meta_path = nil        #path where the overrides for a view should be located

    @profile = profile || :default   #profile will dictate the specific view to use/generate
    @view_name = nil                 #viewName can be either edit,detail,list,etc
    # view_type()                 #tracks the type of view (edit,view,list)
    @js_cache_path = nil             #this is the path to the JS file that will process/render the view
    #view_tpl_cache_path()            #this is the cache path to write the app view tpl to
    @tpl_read_path = nil            #this is the path to read the base tpl file that gets compiled from the view_meta

    @tpl_contents = nil	            #This is contents of template
    @css_require = []
    @js_require = []

    #TBD: dynamically set rather than being hard-wired
    @app_name = "application" 

    #TODO: move these to style.config.r8 to be loaded in constructor
    @style = 
      {:td =>
        {:edit =>
          {:label => 'r8-label-edit',
           :field => 'r8-field-edit'},
         :display =>
          {:label => 'r8-label-display',
           :field => 'r8-field-display'},
         :list =>
          {:col => 'r8-td-col'}
      },
      :th =>
        {:list =>
          {:col => 'r8-th-col',
          :row => 'r8-th-row'}
        }
    }
  end

  def render(view_name)
    @view_name = view_name 
    @form_id = "#{@obj_name}-#{@view_name}-form"
    @view_meta = get_view_meta()

    if viewTPLCurrent?
      @tpl_contents = get_view_tpl_cache()
      @css_require = get_css_require_from_cache()
      @js_require = get_js_require_from_cache()
      return nil
    end

    case (view_type())
      when "edit"
        renderEditTPLCache() 
#       addValidation()
      when "display"
        render_display_tpl_cache()
      when "list"
        render_list_tpl_cache() 
    end
  end
  
  def add_to_css_require(css)
    @css_require << css unless @css_require.includes(css)
  end
  def add_to_js_require(js)
    @js_require << js unless @js_require.includes(js)
  end
 private
  def i18n(*path)
    XYZ::HashObject.nested_value(@i18n_hash,path)
  end
  # This will return the path to write the TPL cache file to
  #TODO:revisit to possibly put randomizer on filename ala smarty
  def view_tpl_cache_path()
    "#{R8::Config[:tplCacheRoot]}/#{@obj_name}/views/#{@profile}.#{@view_name}.eruby"
  end
  def css_require_path()
    "#{R8::Config[:tplCacheRoot]}/#{@obj_name}/views/#{@profile}.#{@view_name}.css_include.json"
  end
  def js_require_path()
    "#{R8::Config[:tplCacheRoot]}/#{@obj_name}/views/#{@profile}.#{@view_name}.js_include.json"
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
    ViewTranslations[@view_name]
  end
  #if not set yet, this will grab/set the meta array for given object/viewType
  # TODO: should have extensible definition of viewName (ie: edit,quickEdit,editInline,etc)
  def get_view_meta()

    R8View::Views[@obj_name] ||= {}
    R8View::Views[@obj_name][@profile] ||= {}
    R8View::Views[@obj_name][@profile][@view_name] ||= {}

    #TODO: revisit to work on override possiblities and for profile handling
    #should check for all view locations, direct and override
    #TODO: figure out best way to do PHP style requires/loading of external meta hashes
    if File.exists?(view_meta_path()) then
       File.open(view_meta_path(), 'r') do |fHandle|
	 R8View::Views[@obj_name][@profile][@view_name] = XYZ::Aux.convert_to_hash_symbol_form(fHandle.read)
       end
    elsif view_meta_path() =~ Regexp.new('(.+)\\.json')
    #TBD: temp conversion
     rb = $1 + ".rb"
      require rb
      File.open(view_meta_path(), 'w') do |fHandle|
         fHandle.write(JSON.pretty_generate(R8View::Views[@obj_name][@profile][@view_name]))
       end
    else
      #TODO: figure out handling of overrides
      #      require $GLOBALS['ctrl']->getAppName().'/objects' . $this->objRef->getObjName() . '/meta/view.'.$this->profile.'.'.$this->viewName.'.php');
      # require 'some path to require'
     raise ErrorNotImplemented.new()
    end
    R8View::Views[@obj_name][@profile][@view_name]
  end

  #This function will set the class property $this->viewMetaPath to appropriate value/location
  def view_meta_path()
    #TBD: error if inputs not set
    "#{R8::Config[:appRootPath]}/#{@app_name}/meta/#{@obj_name}/view.#{@profile}.#{@view_name}.json"
  end

  # This will check to see if the TPL view file exists and isnt stale compare to the base TPL and other factors
  def viewTPLCurrent?()
    viewTPLCachePath = view_tpl_cache_path()
    #TBD: ask Nate about intended semantics; modified because error if file does not exist, but clause executed
    if File.exists?(viewTPLCachePath) && (!R8::Config[:devMode].nil? || R8::Config[:devMode] == false) then
      tplCacheEditTime = File.mtime(viewTPLCachePath).to_i
      viewMetaEditTime = File.mtime(view_meta_path()).to_i
      viewTPLEditTime = File.mtime(get_rtpls_path()).to_i
      #adding this since rendering logic is in this file, might update it w/o changing template,
      #jsTpl should then be updated to reflect changes
      #TODO: switch this when functions moved to js compile class
      # TBD put pick in only if template.r8.rb prefixed by app_name app_name = 'formtests' #TBD: stubbed
      #   templateR8EditTime = File.mtime(R8::Config[:appRootPath] + @app_name + "/template.r8.rb").to_i
      #TBD: below is stub
      templateR8EditTime = File.mtime("#{SYSTEM_DIR}/r8/template.r8.rb").to_i
      if(tplCacheEditTime < templateR8EditTime || tplCacheEditTime < viewMetaEditTime || tplCacheEditTime < viewTPLEditTime) then
        return false
      else
        return true
      end
    else
      return false
    end
  end

  def get_rtpls()
    ret = nil
    File.open(get_rtpls_path(), 'r') do |tpl_file_handle|
      ret = tpl_file_handle.read
    end
    ret
  end

  def get_view_tpl_cache()
    ret = nil
    File.open(view_tpl_cache_path(), 'r') do |tpl_file_handle|
      ret = tpl_file_handle.read
    end
    ret
  end

  def get_css_require_from_cache()
    ret = nil
    File.open(css_require_path(), 'r') do |file_handle|
      ret = XYZ::Aux.convert_to_hash_symbol_form(file_handle.read)
    end
    ret
  end

  def get_js_require_from_cache()
    ret = nil
    File.open(js_require_path(), 'r') do |file_handle|
      ret = XYZ::Aux.convert_to_hash_symbol_form(file_handle.read)
    end
    ret
  end

  # This will return the path to write the TPL cache file to
#TODO: use file.io.php util funcs
  def get_rtpls_path()
#    $overrideTPLPath = $GLOBALS['ctrl']->getAppName().'/objects/'.$this->objRef->getObjName().'/templates/'.$this->profile.'.'.$this->viewName.'.tpl';
#TODO: figure out how to best dynamically load hash meta for base and overrides
    overrideTPLPath = 'some path for overrides here'
    (File.exists?(overrideTPLPath)) ? (return overrideTPLPath) : (return "#{R8::Config[:views_root_dir]}/#{@obj_name}/rtpls/#{@profile}.#{@view_name}.eruby")
  end

  # This function will generate the TPL cache for a view of type list
  def render_list_tpl_cache()
#TODO: can probably move most of this function to a general function call
#and re-use between renderViewJSCache and renderViewHTML
    fieldHandler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

    r8TPL.assign(:objName, @obj_name)
    r8TPL.assign(:viewName, @view_name)

    (!@view_meta[:thRowClass].nil?) ? r8TPL.assign(:thRowClass,@style[:th][:list][:row]) : r8TPL.assign(:thRowClass, @view_meta[:thRowClass])

#TODO: add even/odd tr class handling
    listCols = []
    @view_meta[:fieldList].each do |fieldHash|
      fieldHash.each do |fieldName,fieldMeta|
        fieldMeta[:objName] = @obj_name
        fieldMeta[:name] = fieldName
        fieldMeta[:label] = i18n(:default_list,fieldMeta[:name]) || fieldMeta[:name]
        fieldMeta[:id] = fieldMeta[:name] if fieldMeta[:id].nil?
        fieldMeta[:class] = @style[:td][:list][:col] if fieldMeta[:class].nil?
        fieldMeta[:content] = fieldHandler.getField(view_type(), fieldMeta, 'tpl')
        listCols << fieldMeta
      end
    end

    objName = @obj_name
    #build & assign the foreach header for the JS template
    r8TPL.assign(:foreachHeaderContent,'{%for '+objName.to_s+' in '+ objName.to_s+'_list%}')
    r8TPL.assign(:trClass, '{%='+obj_name.to_s+'[:class]%}')
    r8TPL.assign(:cols, listCols);

    #this might be temp until figuring out if template literals are possible
    r8TPL.assign(:listStartPrevVar, '{%=listStartPrev%}')
    r8TPL.assign(:listStartNextVar, '{%=listStartNext%}')
    r8TPL.assign(:iteratorVar, '{%='+objName.to_s+'%}')
    r8TPL.assign(:endTag, '{%end%}')

    @tpl_contents = r8TPL.render(get_rtpls())
    fwrite()
  end

  # This function will return the path for the given viewName (detail,edit,list,etc)
  # If the template/cache/path do not exist or is stale it will generate a new one

  # This will add js calls to add each field to form validation
  def addValidation()
    fieldHandler = FieldR8.new(self)

    @view_meta[:fieldGroups].each do |groupNum,groupHash|
      @view_meta[:fieldSets][groupNum][:fields].each do |fieldNum,fieldHash|
        next if(fieldArray.length == 0)

        fieldHash.each do |fieldName,fieldMeta|
          fieldMeta[:fieldName] = fieldName
          if(!fieldMeta[:id].nil?) then fieldMeta[:id] = fieldMeta[:fieldName] end
          fieldMeta[:objName] = @obj_name
          fieldHandler.addValidation(@form_id, fieldMeta)
        end
      end
    end
  end



  # This function will generate the TPL cache for a view of type edit
  def renderEditTPLCache()
#TODO: can probably move most of this function to a general function call
#and re-use between renderViewJSCache and renderViewHTML
    fieldHandler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

    r8TPL.assign(:formId, @form_id)
    r8TPL.assign(:formAction, @view_meta[:action])

    (@view_meta[:tdLabelClass].nil?) ? tdLabelClass = @style[:td][:edit][:label] : tdLabelClass = @view_meta[:tdLabelClass]

    (@view_meta[:tdFieldClass].nil?) ? tdFieldClass =@style[:td][:edit][:field] : tdFieldClass = @view_meta[:tdFieldClass]

    #add any form hidden fields
    hiddenFields = []
    @view_meta[:hiddenFields].each do |hFieldHash|
      hFieldHash.each do |fieldName,fieldMeta|
        fieldMeta[:name] = fieldName.to_s
        if(fieldMeta[:id].nil?) then fieldMeta[:id] = fieldMeta[:name] end
        hiddenFields << fieldMeta
      end
    end
    r8TPL.assign(:hFieldList, hiddenFields)

    rows = []
    groupNum = 0
    @view_meta[:fieldGroups].each do |groupHash|
      rowCount = 0
      displayLabels = groupHash[:displayLabels]
      numCols = groupHash[:numCols].to_i
      colIndex = 0
      fieldNum = 0
      rows[rowCount] = {}
      rows[rowCount][:cols] = []

      groupHash[:fields].each do |fieldHash|
        fieldNum +=1
        rows[rowCount][:rowId] = 'g'+groupNum.to_s+'-r'+rowCount.to_s
        #if size is 0 then its a blank spot in the form
        if(fieldHash.length == 0) then
          rows[rowCount][:cols][colIndex] = {}
          rows[rowCount][:cols][colIndex][:class] = tdLabelClass
          rows[rowCount][:cols][colIndex][:content] = '&amp;nbsp;'
          rows[rowCount][:cols][colIndex][:colId] = 'r'+rowCount.to_s+'-c'+colIndex.to_s+'-label'
          colIndex+=1
          rows[rowCount][:cols][colIndex] = {}
          rows[rowCount][:cols][colIndex][:class] =  tdFieldClass
          rows[rowCount][:cols][colIndex][:content] = '&amp;nbsp;'
          rows[rowCount][:cols][colIndex][:colId] = 'r'+rowCount.to_s+'-c'+colIndex.to_s+'-field'
        else
          fieldHash.each do |fieldName,fieldMeta|
            fieldMeta[:name] = fieldName.to_sym
            if(fieldMeta[:id].nil?) then fieldMeta[:id] = fieldMeta[:name] end
            fieldMeta[:objName] = @obj_name
            #do label
            rows[rowCount][:cols][colIndex] = {}
            if(displayLabels) then
              rows[rowCount][:cols][colIndex][:content] = ((!i18n(:default_edit,fieldMeta[:name].to_sym).nil?) ? i18n(:default_edit,fieldMeta[:name].to_sym) : fieldMeta[:name])
            else
              rows[rowCount][:cols][colIndex][:content] = '&nbsp;'
            end
            rows[rowCount][:cols][colIndex][:class] = tdLabelClass
            rows[rowCount][:cols][colIndex][:colId] = fieldMeta[:name].to_s+"-label"
            colIndex+=1
            rows[rowCount][:cols][colIndex] = {}
            #do field
            rows[rowCount][:cols][colIndex][:colId] = fieldMeta[:name].to_s+"-field"
            rows[rowCount][:cols][colIndex][:content] = fieldHandler.getField(view_type(), fieldMeta, 'tpl')
            rows[rowCount][:cols][colIndex][:class] = tdFieldClass
          end
        end
        #if remainder is 0 then its time to start rendering the next row, increment row, reset col
        if(fieldNum.remainder(numCols) == 0) then
          rowCount+=1
          colIndex = 0
          rows[rowCount] = {}
          rows[rowCount][:cols] = []
        else 
          colIndex+=1
        end
        #end of field interation
      end
      #end of group interation
      groupNum +=1
    end
    r8TPL.assign(:rows, rows)

    @tpl_contents = r8TPL.render(get_rtpls())
    fwrite()
  end

  # This function will generate the TPL cache for a view of type display
  def render_display_tpl_cache()
#TODO: can probably move most of this function to a general function call
#and re-use between renderViewJSCache and renderViewHTML
    fieldHandler = FieldR8.new(self)
    r8TPL = R8Tpl::TemplateR8.new
    r8TPL.js_templating_on = false   #template engine should catch non JS automatically, but forcing to be sure

    r8TPL.assign(:formId, @form_id)
    r8TPL.assign(:formAction, @view_meta[:action])

    (@view_meta[:tdLabelClass].nil?) ? tdLabelClass = @style[:td][:edit][:label] : tdLabelClass = @view_meta[:tdLabelClass]

    (@view_meta[:tdFieldClass].nil?) ? tdFieldClass =@style[:td][:edit][:field] : tdFieldClass = @view_meta[:tdFieldClass]

    #add any form hidden fields
    hiddenFields = []
    @view_meta[:hiddenFields].each do |hFieldHash|
      hFieldHash.each do |fieldName,fieldMeta|
        fieldMeta[:name] = fieldName.to_s
        if(fieldMeta[:id].nil?) then fieldMeta[:id] = fieldMeta[:name] end
        hiddenFields << fieldMeta
      end
    end
    r8TPL.assign(:hFieldList, hiddenFields)

    rows = []
    groupNum = 0
    @view_meta[:fieldGroups].each do |groupHash|
      rowCount = 0
      displayLabels = groupHash[:displayLabels]
      numCols = groupHash[:numCols].to_i
      colIndex = 0
      fieldNum = 0
      rows[rowCount] = {}
      rows[rowCount][:cols] = []

      groupHash[:fields].each do |fieldHash|
        fieldNum +=1
        rows[rowCount][:rowId] = 'g'+groupNum.to_s+'-r'+rowCount.to_s
        #if size is 0 then its a blank spot in the form
        if(fieldHash.length == 0) then
          rows[rowCount][:cols][colIndex] = {}
          rows[rowCount][:cols][colIndex][:class] = tdLabelClass
          rows[rowCount][:cols][colIndex][:content] = '&amp;nbsp;'
          rows[rowCount][:cols][colIndex][:colId] = 'r'+rowCount.to_s+'-c'+colIndex.to_s+'-label'
          colIndex+=1
          rows[rowCount][:cols][colIndex] = {}
          rows[rowCount][:cols][colIndex][:class] =  tdFieldClass
          rows[rowCount][:cols][colIndex][:content] = '&amp;nbsp;'
          rows[rowCount][:cols][colIndex][:colId] = 'r'+rowCount.to_s+'-c'+colIndex.to_s+'-field'
        else
          fieldHash.each do |fieldName,fieldMeta|
            fieldMeta[:name] = fieldName.to_sym
            if(fieldMeta[:id].nil?) then fieldMeta[:id] = fieldMeta[:name] end
            fieldMeta[:objName] = @obj_name
            #do label
            rows[rowCount][:cols][colIndex] = {}
            if(displayLabels) then
              rows[rowCount][:cols][colIndex][:content] = ((!i18n(:default_edit,fieldMeta[:name].to_sym).nil?) ? i18n(:default_edit,fieldMeta[:name].to_sym) : fieldMeta[:name])
            else
              rows[rowCount][:cols][colIndex][:content] = '&nbsp;'
            end
            rows[rowCount][:cols][colIndex][:class] = tdLabelClass
            rows[rowCount][:cols][colIndex][:colId] = fieldMeta[:name].to_s+"-label"
            colIndex+=1
            rows[rowCount][:cols][colIndex] = {}
            #do field
            rows[rowCount][:cols][colIndex][:colId] = fieldMeta[:name].to_s+"-field"
            rows[rowCount][:cols][colIndex][:content] = fieldHandler.getField(view_type(), fieldMeta, 'tpl')
            rows[rowCount][:cols][colIndex][:class] = tdFieldClass
          end
        end
        #if remainder is 0 then its time to start rendering the next row, increment row, reset col
        if(fieldNum.remainder(numCols) == 0) then
          rowCount+=1
          colIndex = 0
          rows[rowCount] = {}
          rows[rowCount][:cols] = []
        else 
          colIndex+=1
        end
        #end of field interation
      end
      #end of group interation
      groupNum +=1
    end
    r8TPL.assign(:rows, rows)

    @tpl_contents = r8TPL.render(get_rtpls())
    fwrite()
  end

  #writes template, js_include and css_include
  def fwrite()
    files = 
      {view_tpl_cache_path() => @tpl_contents,
       css_require_path() => JSON.pretty_generate(@css_require),
       js_require_path() => JSON.pretty_generate(@js_require)
      }

    files.each do |path, contents| 
      File.open(path, 'w') do |fHandle|
        fHandle.write(contents)
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
