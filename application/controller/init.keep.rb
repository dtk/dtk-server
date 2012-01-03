#TODO: most of these shoudl be helpers
require File.expand_path(SYSTEM_DIR+'/common_mixin.r8', File.dirname(__FILE__))

module XYZ
  class UserContext
    attr_reader :current_profile,:request,:json_response

    def initialize(controller)
      @current_profile = :default
      @request = controller.request
      @json_response = controller.json_response?
      @controller = controller
   end

    def create_object_from_id(id)
      @controller.create_object_from_id(id)
    end
  end
end

module XYZ
  class Controller < Ramaze::Controller
    helper :common
    helper :process_search_object
    helper :user
    trait :user_model => XYZ::User
    include R8Tpl::CommonMixin
    include R8Tpl::Utility::I18n

    provide(:html, :type => 'text/html'){|a,s|s} #lamba{|a,s|s} is fn called after bundle and render for a html request
    provide(:json, :type => 'application/json'){|a,s|s} 

    layout :bundle_and_return


    #TODO: work around to handle falser8 calls
    def falser8(*args)
      {:content => nil}
    end

    def ret_session_context_id()
      #stub
      2
    end

    ### user processing
    def login_first
      auth_violation_response() unless logged_in? 
    end

    def auth_violation_response()
      rest_request? ? respond('Not Authorized',403) : redirect(R8::Config[:login][:path])
    end

    def get_user()
      return nil unless user.kind_of?(Hash)
      @cached_user_obj ||= User.new(user,ret_session_context_id(),:user)
    end
    #########


    def initialize
      super
      @cached_user_obj = nil
      #TODO: see where these are used; remove if not used
      @public_js_root = R8::Config[:public_js_root]
      @public_css_root = R8::Config[:public_css_root]
      @public_images_root = R8::Config[:public_images_root]

      #TBD: may make a calls fn that declares a cached var to be 'self documenting'
      @model_name = nil #cached ; called on demand

      #used when action set calls actions
      @parsed_query_string = nil

      @css_includes = Array.new
      @js_includes = Array.new
      @js_exe_list = Array.new

      @user_context = nil

      @layout = nil

      #if there is an action set then call by value is used to substitue in child actions; this var
      #will be set to have av pairs set from global params given in action set call
      @action_set_param_map = Hash.new

      @ctrl_results = Hash.new
      @ctrl_results[:as_run_list] = Array.new

    end

    def json_response?()
      @json_response ||= rest_request?() or ajax_request?() 
    end
    def rest_request?()
      @rest_request ||= request.env["REQUEST_PATH"] =~ Regexp.new("^/rest")
    end
    def ajax_request?
      @ajax_request ||=  ajax_request_aux?()
    end
    def ajax_request_aux?()
      route_pieces = request.env["PATH_INFO"].split("/")
      last_piece = route_pieces[route_pieces.size-1]
      return true if /\.json/.match(last_piece)

      return true if request.params["iframe_upload"] == "1"

      return (request.env["HTTP_X_REQUESTED_WITH"] && request.env["HTTP_X_REQUESTED_WITH"]=="XMLHttpRequest" )
    end

    ### layout processing fn
    def bundle_and_return

      #TODO: leave these here until pushing examples into route config or ctrl
#      include_css(layout_name)
#      include_js('example')

#TODO: maybe move this down the road
=begin moved
      cache_file_name = "#{R8::Config[:js_file_write_path]}/model_defs.cache.js"
      if !File.exists?(cache_file_name)
        build_model_defs_js_cache()
      end
      include_js('cache/model_defs.cache')

      cache_file_name = "#{R8::Config[:js_file_write_path]}/model.i18n.cache.js"
      if !File.exists?(cache_file_name)
        build_model_i18n_js_cache(user_context())
      end
      include_js('cache/model.i18n.cache')
=end
      return  rest_response() if rest_request?()

      include_js('cache/model_defs.cache')
      include_js('cache/model.i18n.cache')
      #TODO: get things cleaned up after implemented :json/js responses
      unless json_response?()

        #TODO: rather than using  @layout; may calculate it dynamically here
        layout_name = "#{@layout || :default}.layout"

        js_includes = Array.new
        css_includes = Array.new
        js_exe_list = Array.new

        panels_content = Hash.new
        @ctrl_results[:as_run_list].each do |action_namespace|
          (@ctrl_results[action_namespace][:content]||[]).each do |content_item|
            assign_type = content_item[:assign_type]
            panel = content_item[:panel]
            content = content_item[:content]

            case assign_type
              when :append 
                (panels_content[panel].nil?) ? 
                panels_content[panel] = content : 
                  panels_content[panel] << content
              when :replace 
                panels_content[panel] = content
              when :prepend 
                if(panels_content[panel].nil?) 
                  panels_content[panel] = content
                else
                  tmp_contents = panels_content[panel]
                  panels_content[panel] = content + tmp_contents
                end
            end
          end

          if !@ctrl_results[action_namespace][:js_includes].nil?
            @ctrl_results[action_namespace][:js_includes].each { |js_include| js_includes << js_include }
          end
          if !@ctrl_results[action_namespace][:css_includes].nil?
            @ctrl_results[action_namespace][:css_includes].each { |css_include| css_includes << css_include }
          end

          if !@ctrl_results[action_namespace][:js_exe_list].nil?
            @ctrl_results[action_namespace][:js_exe_list].each { |js_exe| js_exe_list << js_exe }
          end

          #TODO: process js_exe_scripts
        end

#TODO: temp hack, need to figure out how to get js cache files included better way
        @js_includes.each { |js_include| js_includes << js_include }
#        js_exe_list << 'R8.Model.initModelDefs();';

        #set template vars
        _app = {
          :js_includes => js_includes,
          :css_includes => css_includes,
          :js_exe_list => js_exe_list,
          :base_uri => R8::Config[:base_uri],
          :base_css_uri => R8::Config[:base_css_uri],
          :base_js_uri => R8::Config[:base_js_uri],
          :base_images_uri => R8::Config[:base_images_uri],
        }
        template_vars = {
          :_app => _app,
          :main_menu => String.new,
          :left_col => String.new
        }

        panels_content.each { |key,value|
          template_vars[key] = value
        }
        ##end set template vars

#TODO: what is :layout for in the class sig?
        tpl = R8Tpl::TemplateR8.new(layout_name,user_context(),:layout)
        template_vars.each{|k,v|tpl.assign(k.to_sym,v)}
        tpl_return = tpl.render()

        return tpl_return
      else
#TODO: more fully implement config passing between server/client
        @ctrl_results[:config] = {
          :base_uri => "#{R8::Config[:base_uri]}/xyz",
          :date_format => 'MM/DD/YY',
          :time_format => '12:00',
          :etc => 'etc'
        }
        return JSON.pretty_generate(@ctrl_results)
      end
    end

    def rest_response()
      #TODO: needs to be cleaned up
      raise rest_response_error unless app_key =  @ctrl_results.keys.find{|k|k.to_s =~ /^application/}
      raise rest_response_error unless outer_content = @ctrl_results[app_key][:content]
      raise rest_response_error unless outer_content.size == 1
      outer_content.first[:content]
    end

    def include_css(css_name)
      @css_includes << R8::Config[:base_css_uri] + '/' + css_name + '.css'
    end

#TODO: augment with priority param when necessary
    def include_js(js_name)
      @js_includes << R8::Config[:base_js_uri] + '/' + js_name + '.js'
    end

    def include_js_tpl(js_tpl_name)
      @js_includes << R8::Config[:base_js_uri] + '/cache/' + js_tpl_name
    end

    def add_js_exe(js_content)
      @js_exe_list << js_content
    end

    def run_javascript(js_content)
      @js_exe_list << js_content
    end

    def ret_js_includes()
      includes_ret = @js_includes
      @js_includes = Array.new
      return includes_ret
    end

    def ret_css_includes()
      includes_ret = @css_includes
      @css_includes = Array.new
      return includes_ret
    end

    def ret_js_exe_list()
      exe_list = @js_exe_list
      @js_exe_list = Array.new
      return exe_list
    end
######
#error handling
    def handle_errors(&block)
      begin
        yield
      rescue ErrorForUser => e
        {:data=> {
            "error" => {
              "error_code" => 1,
              "error_msg" => e.to_s
            }
          }
        }
      end
    end

#####################################################
    ### MAIN ACTION DEFS
#####################################################

    def list()
      user
      search_object =  ret_search_object_in_request()
      raise Error.new("no search object in request") unless search_object

      if search_object.needs_to_be_retrieved?
        search_object.retrieve_from_saved_object!()
      elsif search_object.should_save?
        search_object.save(model_handle(:search_object))
      end

      #only create if need to and appropriate to do so
      search_object.save_list_view_in_cache?(user_context())

      paging_info = search_object.paging
      order_by_list = search_object.order_by

      _model_var = {:i18n => get_model_i18n(model_name().to_s,user_context())}

#TODO: figure out clean way to seperate search out
#TODO hack that for testing, which now only implemented by node
      search_content = nil
      if model_name() == :node or model_name() == :component or model_name() == :attribute
#      if model_name() == :node 
        tpl = R8Tpl::TemplateR8.new("#{model_name()}/search",user_context())

        #where clause {:relation => model_name().to_s} makes sure that only search queries of relevant type returned
        _saved_search_list = get_objects(:search_object,{:relation => model_name().to_s})

#TODO: temp until more fully implementing select fields to be called in one off manner,right now
#select field for saved search dropdown is coded into view render search function
        (_saved_search_list||[]).each_with_index do |so,index|
          _saved_search_list[index][:selected] = (search_object && search_object[:id] == so[:id]) ? 'selected="1"' : ''
        end

        if(!search_object[:id])
          search_context = model_name().to_s+'-list'
          search_id = 'new';
          search_object[:id] = search_id
          add_js_exe("R8.Search.newSearchContext('#{search_context}');")
          add_js_exe("R8.Search.addSearchObj('#{search_context}',#{search_object.json});")
        else
          search_context = model_name().to_s+'-list'
          search_id = search_object[:id]
          add_js_exe("R8.Search.newSearchContext('#{search_context}');")
          add_js_exe("R8.Search.addSearchObj('#{search_context}',#{search_object.json});")
        end

        tpl.assign("_saved_search_list",_saved_search_list)
        tpl.assign("num_saved_searches",_saved_search_list.length)
        (_saved_search_list||[]).each do |so|
          if(search_id != so[:id])
            add_js_exe("R8.Search.addSearchObj('#{search_context}',#{so.json});")
          end
        end
 
        add_js_exe("R8.Search.initSearchContext('#{search_context}','#{search_id}');")
        tpl.assign(:search_id,search_id)

        tpl.assign("_#{model_name().to_s}",_model_var)
#        tpl.assign("#{search_context}-current_start",(paging_info||{})[:start]||0)
        tpl.assign(:current_start,(paging_info||{})[:start]||0)
        tpl.assign(:_app,app_common())
        tpl.assign(:search_id,search_id)
        tpl.assign(:search_context,search_context)

        field_set = Model::FieldSet.default(model_name)
        model = ret_model_for_list_search(field_set)
        tpl.assign(:model_name,model_name().to_s)
        tpl.assign("#{model_name().to_s}",model)

        search_content = tpl.render()
      end
#end search testing hack

      template_name = search_object.saved_search_template_name() || "#{model_name()}/#{default_action_name()}"
      tpl = R8Tpl::TemplateR8.new(template_name,user_context())
      field_set = search_object.field_set

      tpl.assign(:search_content, search_content)
      set_template_order_columns!(tpl,order_by_list,field_set)
      set_template_paging_info!(tpl,paging_info)

 #     opts = {:page => paging_info,:order_by => order_by_list}
#TODO: parent id is right now passed in opts, may change
#      opts.merge!(:parent_id => parent_id) if parent_id
#      model_list = get_objects(model_name(),where_clause,opts)

#TODO: temp hack to have default view only include component instances
component_default = nil
if search_object[:search_pattern].is_default_view? and  model_name() == :component
  search_object[:search_pattern][:filter] = [:neq,:node_node_id,nil]
  component_default = true
end

      model_list = Model.get_objects_from_search_object(search_object)

#TODO: temp hack to have default view only include component instances
if component_default 
  model_list.reject!{|r|not id_handle(r[:node_node_id],:node)[:parent_model_name]==:datacenter}
end
      if model_name() == :node
        model_defs = get_model_defs(model_name())
        model_list.each_with_index do |model_obj,index|
          model_obj.each do |field,value|
            if model_defs[:field_defs][field] && (model_defs[:field_defs][field][:type] == 'select' || model_defs[:field_defs][field][:type] == 'multiselect')
              display_key = field.to_s+'_display'
              model_list[index][display_key.to_sym] = _model_var[:i18n][:options_list][field][value]
            end
          end
        end
      end

      tpl.assign("#{model_name().to_s}_list",model_list)
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign(:search_context,search_context)
      tpl.assign(:_app,app_common())

      panel_id = request.params['panel_id'] || 'main_body'

      model_name = model_name().to_s
      run_javascript("R8.InventoryView.init('#{model_name}');")

      return {
          :content => tpl.render(),
          :panel_id => panel_id
      }
    end

    def list2()
      panel_id = request.params['panel_id'] || 'main_body'
pp '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
pp panel_id
=begin
{"paging"=>"",
 "search_name"=>"template search",
 "search"=> "{
    \"relation\":null,
    \"id\":\"\",
    \"search_pattern\":{
      \":columns\":[\":containing_datacenter\",\":parent_name\",\":display_name\"],
      \":filter\":[\":and\",[\":eq\",\":type\",\"template\"]],
      \":order_by\":[],
      \":paging\":{},
      \":relation\":\"component\"
    },
    \"display_name\":\"template search\"}",
 "order_by"=>""}
=end
#pp [:user, get_user]
#pp request.params
#pp '&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'

      search_object =  ret_search_object_in_request()
      raise Error.new("no search object in request") unless search_object

      if search_object.needs_to_be_retrieved?
        search_object.retrieve_from_saved_object!()
      elsif search_object.should_save?
        search_object.save
      end

      #only create if need to and appropriate to do so
      search_object.save_list_view_in_cache?(user_context())

      paging_info = search_object.paging
      order_by_list = search_object.order_by

      _model_var = {:i18n => get_model_i18n(model_name().to_s,user_context())}

#TODO: figure out clean way to seperate search out
#TODO hack that for testing, which now only implemented by node
      search_content = nil
      if model_name() == :node or model_name() == :component or model_name() == :attribute
#      if model_name() == :node 
        tpl = R8Tpl::TemplateR8.new("#{model_name()}/search",user_context())

        #where clause {:relation => model_name().to_s} makes sure that only search queries of relevant type returned
        _saved_search_list = get_objects(:search_object,{:relation => model_name().to_s})

#TODO: temp until more fully implementing select fields to be called in one off manner,right now
#select field for saved search dropdown is coded into view render search function
        (_saved_search_list||[]).each_with_index do |so,index|
          _saved_search_list[index][:selected] = (search_object && search_object[:id] == so[:id]) ? 'selected="1"' : ''
        end

        if(!search_object[:id])
          search_context = model_name().to_s+'-list'
          search_id = 'new';
          search_object[:id] = search_id
#          add_js_exe("R8.Search.newSearchContext('#{search_context}');")
#          add_js_exe("R8.Search.addSearchObj('#{search_context}',#{search_object.json});")
        else
          search_context = model_name().to_s+'-list'
          search_id = search_object[:id]
#          add_js_exe("R8.Search.newSearchContext('#{search_context}');")
#          add_js_exe("R8.Search.addSearchObj('#{search_context}',#{search_object.json});")
        end

        tpl.assign("_saved_search_list",_saved_search_list)
        tpl.assign("num_saved_searches",_saved_search_list.length)
        (_saved_search_list||[]).each do |so|
          if(search_id != so[:id])
#            add_js_exe("R8.Search.addSearchObj('#{search_context}',#{so.json});")
          end
        end
 
#        add_js_exe("R8.Search.initSearchContext('#{search_context}','#{search_id}');")
        tpl.assign(:search_id,search_id)

        tpl.assign("_#{model_name().to_s}",_model_var)
#        tpl.assign("#{search_context}-current_start",(paging_info||{})[:start]||0)
        tpl.assign(:current_start,(paging_info||{})[:start]||0)
        tpl.assign(:_app,app_common())
        tpl.assign(:search_id,search_id)
        tpl.assign(:search_context,search_context)

        field_set = Model::FieldSet.default(model_name)
        model = ret_model_for_list_search(field_set)
        tpl.assign(:model_name,model_name().to_s)
        tpl.assign("#{model_name().to_s}",model)
        search_content = tpl.render()
      end
#end search testing hack

      template_name = search_object.saved_search_template_name() || "#{model_name()}/#{default_action_name()}"
      tpl = R8Tpl::TemplateR8.new(template_name,user_context())
      field_set = search_object.field_set

      tpl.assign(:search_content, search_content)
      set_template_order_columns!(tpl,order_by_list,field_set)
      set_template_paging_info!(tpl,paging_info)

      model_list = Model.get_objects_from_search_object(search_object)
      if model_name() == :node
        model_defs = get_model_defs(model_name())
        model_list.each_with_index do |model_obj,index|
          model_obj.each do |field,value|
            if model_defs[:field_defs][field] && (model_defs[:field_defs][field][:type] == 'select' || model_defs[:field_defs][field][:type] == 'multiselect')
              display_key = field.to_s+'_display'
              model_list[index][display_key.to_sym] = _model_var[:i18n][:options_list][field][value]
            end
          end
        end
      end

      tpl.assign("#{model_name().to_s}_list",model_list)
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign(:search_context,search_context)
      tpl.assign(:_app,app_common())

      return {
        :content => tpl.render(),
        :panel => panel_id
      }
    end

    #TODO: id and parsed query string shouldnt be passed, id should be available from route string
    #TODO: need to figure out best way to handle parsed_query_string
    def display(id,parsed_query_string=nil)
      #how does it know what object to get?
      model_result = get_object_by_id(id)

      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{default_action_name()}",user_context())
      tpl.assign(model_name(),model_result)

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      if model_name() == :node
        model_defs = get_model_defs(model_name())
        model_result.each do |field,value|
          if model_defs[:field_defs][field] && (model_defs[:field_defs][field][:type] == 'select' || model_defs[:field_defs][field][:type] == 'multiselect')
            display_key = field.to_s+'_display'
            model_result[display_key.to_sym] = _model_var[:i18n][:options_list][field][value]
          end
        end
      end

      return {:content => tpl.render()}
    end

    #TODO: need to figure out best way to handle parsed_query_string
    def edit(id,parsed_query_string=nil)
      model_result = get_object_by_id(id)

      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{default_action_name()}",user_context())
      tpl.assign(model_name(),model_result)

      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      if model_name() == :node
        model_defs = get_model_defs(model_name())
        model_result.each do |field,value|
          if model_defs[:field_defs][field]
            case model_defs[:field_defs][field][:type]
              when 'select','multiselect'
                options_list = _model_var[:i18n][:options_list][field]
                ol_key = (field.to_s+'_options_list').to_sym
                model_result[ol_key] = Hash.new
                options_list.each do |value,label|
                  value_key = value+'_selected'
                  model_result[ol_key][value_key.to_sym] = (model_result[field] == value) ? ' selected="true"' : ''
                end
#                display_key = field.to_s+'_display'
#                model_result[display_key.to_sym] = _model_var[:i18n][:options_list][field][value]
              when 'date'
            end
          end
        end
      end
      return {:content => tpl.render()}
    end
    ### end of main action defs

    #update or create depending on whether id is in post content
    def save(explicit_hash=nil,opts={})
      hash = explicit_hash || request.params.dup
      ### special fields
      id = hash.delete("id")
      id = nil if id.kind_of?(String) and id.empty?
      parent_id = hash.delete("parent_id")
      parent_model_name = hash.delete("parent_model_name")
      model_name = hash.delete("model")
      name = hash.delete("name") || hash["display_name"]
      redirect = (not (hash.delete("redirect").to_s == "false"))

      #TODO: revisit during cleanup, return_model used for creating links
      rm_val = hash.delete("return_model")
      return_model = rm_val && rm_val == "true"
      
      #TODO: fix up encapsulate translating from raw_hash to one for model
      cols = Model::FieldSet.all_settable(model_name) 
      #delete all elements in hash that are not actual or virtual settable columns or ones that are null or have empty string value
      hash.each do |k,v|
        keep = (cols.include_col?(k.to_sym) and hash[k] and not (hash[k].respond_to?(:empty?) and hash[k].empty?))
        unless keep
          Log.info("in save function removing illegal column #{k} from model #{model_name}")
          hash.delete(k) 
        end
      end

      if id 
        #update
        update_from_hash(id.to_i,hash)
      else
        #create
        #TODO: cleanup confusion over hash and string leys
        hash.merge!({:display_name => name}) unless (hash.has_key?(:display_name) or hash.has_key?("display_name"))
        parent_id_handle = nil
        create_hash = nil
        if parent_id
          parent_id_handle = id_handle(parent_id,parent_model_name)
          create_hash = {model_name.to_sym => {name => hash}}
        else
          parent_id_handle = top_level_factory_id_handle()
          create_hash = {name.to_sym => hash}
        end
        new_id = create_from_hash(parent_id_handle,create_hash)
        id = new_id if new_id
      end

      if return_model
        return {:data=> get_object_by_id(id)}
      end
    
      return id if opts[:return_id]
      redirect "/xyz/#{model_name()}/display/#{id.to_s}" if redirect
    end

    def clone(id)
      handle_errors do
        id_handle = id_handle(id)
        hash = request.params
        target_id_handle = nil
        if hash["target_id"] and hash["target_model_name"]
          input_target_id_handle = id_handle(hash["target_id"].to_i,hash["target_model_name"].to_sym)
          target_id_handle = Model.find_real_target_id_handle(id_handle,input_target_id_handle)
        else
          Log.info("not implemented yet")
          return redirect "/xyz/#{model_name()}/display/#{id.to_s}"
        end

        #TODO: need to copy in avatar when hash["ui"] is non null
        override_attrs = hash["ui"] ? {:ui=>hash["ui"]} : {}
        target_object = target_id_handle.create_object()
        clone_opts = id_handle.create_object().source_clone_info_opts()
        new_obj = target_object.clone_into(id_handle.create_object(),override_attrs,clone_opts)
        id = new_obj && new_obj.id()

#TODO: clean this up,hack to update UI params for newly cloned object
#      update_from_hash(id,{:ui=>hash["ui"]})

#      hash["redirect"] ? redirect_route = "/xyz/#{hash["redirect"]}/#{id.to_s}" : redirect_route = "/xyz/#{model_name()}/display/#{id.to_s}"

        if hash["model_redirect"]
          base_redirect = "/xyz/#{hash["model_redirect"]}/#{hash["action_redirect"]}"
          redirect_id =  hash["id_redirect"].match(/^\*/) ? id.to_s : hash["id_redirect"]
          redirect_route = "#{base_redirect}/#{redirect_id}"
          request_params = ''
          expected_params = ['model_redirect','action_redirect','id_redirect','target_id','target_model_name']
          request.params.each do |name,value|
            if !expected_params.include?(name)
              request_params << '&' if request_params != ''
              request_params << "#{name}=#{value}"
            end
          end
          ajax_request? ? redirect_route += '.json' : nil
          redirect_route << URI.encode("?#{request_params}") if request_params != ''
        else
          redirect_route = "/xyz/#{model_name()}/display/#{id.to_s}"
          ajax_request? ? redirect_route += '.json' : nil
        end

        redirect redirect_route
      end
    end

   private
    def user_context()
      @user_context ||= UserContext.new(self)
    end

    ######################
    #####Helper fns

#TODO: should be pushed down to model or something
    def setup_fields_for_display(model)
      model_def = get_model_defs(model_name().to_s)
      model.each do |field,value|
        field_sym = field.sym
#TODO: temp until fully implemented
        model_def[field_sym] = {}
        model_def[field_sym][:type] = 'etc'
        case model_def[field_sym][:type]
          when "select"
            setup_options_field(model,field_sym,model_def[field_sym])
          when "date"
          when "checkbox"
          when "etc"
        end
      end
    end

#TODO: model meant to be handled and edited in reference style
    def setup_options_field(model,field,model_def)
      field_value = model[field]
      display_col = (field.to_s+'_display').to_sym
      model_options = get_model_options(model().to_s)
      model[display_col] = model_options[field][field_value]
  
      model_options[field].each do |key,option_value|
        (field_value == option_value) ? object[(option_value+'_selected').to_sym] = ' selected' : object[(option_value+'_selected').to_sym] = ''
      end
    end

    def http_host()
      request.env["HTTP_HOST"]
    end

    #TBD: using temporaily before writing my owb error handling; from Toth
    # will make this an errior helper
    def error_405
      error_layout 405, '405 Method Not Allowed', %[
        <p>
          The #{request.env['REQUEST_METHOD']} method is not allowed for the
          requested URL.
        </p>
      ]
    end

    def error_layout(status, title, content = '')
      respond! %[
        <html>
          <head>
            <title>#{h(title)}</title>
          </head>
          <body>
            <h1>#{h(title)}</h1>
            #{content}
          </body>
        </html>
      ].unindent, status
    end

#TODO: this shouldnt be a controller method, should be in some util class or something
    # html rendering helpers
    def html_render_component_href(ref,component)
      href = component[:link][:href] if component[:link]
      href ||= ""
      display = component[:display_name]
      display ||= ""
      "<a href=" + '"' + href + '">' + display + "</a>"
    end
  end
end

# system fns for controller
require __DIR__('action_set')

#TODO: Should all controllers/models be loaded, or load just base, and rest dynamically

# Here go your requires for subclasses of Controller:
#require __DIR__('admin')
#require __DIR__('data_source')
%w{ide project import implementation library target inventory workspace state_change datacenter node_group node node_interface component attribute attribute_link port_link monitoring_item search_object viewspace user task assembly editor file_asset}.each do |controller_file|
  require __DIR__(controller_file)
end

