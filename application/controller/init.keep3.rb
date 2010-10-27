require File.expand_path(SYSTEM_DIR+'/common_mixin.r8', File.dirname(__FILE__))
require File.expand_path(SYSTEM_DIR+'/utility.r8', File.dirname(__FILE__))

module XYZ
  class UserContext
    attr_reader :current_profile,:request,:json_response

    def initialize(request,json_response)
      @current_profile = :default
      @request = request
      @json_response = json_response
   end
  end
end

module XYZ
  class Controller < Ramaze::Controller
    helper :common
    include R8Tpl::CommonMixin
    include R8Tpl::Utility::I18n

    provide(:html, :type => 'text/html'){|a,s|s} #lamba{|a,s|s} is fn called after bundle and render for a html request
    provide(:json, :type => 'application/json'){|a,s|s} 

    layout :bundle_and_return

    def initialize
      super
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

      @json_response = false
    end

    def ajax_request?
      route_pieces = request.env["PATH_INFO"].split("/")
      last_piece = route_pieces[route_pieces.size-1]
      return true if /\.json/.match(last_piece)

      return (request.env["HTTP_X_REQUESTED_WITH"] && request.env["HTTP_X_REQUESTED_WITH"]=="XMLHttpRequest" )
    end

    ### layout processing fn
    def bundle_and_return

      #TODO: leave these here until pushing examples into route config or ctrl
#      include_css(layout_name)
#      include_js('example')

      #TODO: get things cleaned up after implemented :json/js responses
      if !@json_response

        #TODO: rather than using  @layout; may calculate it dynamically here
        layout_name = "#{@layout || :default}.layout"

        js_includes = Array.new
        css_includes = Array.new
        js_exe_list = Array.new

        panels_content = Hash.new
        @ctrl_results[:as_run_list].each do |action_namespace|
          @ctrl_results[action_namespace][:content].each do |content_item|
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

    def include_css(css_name)
      @css_includes << R8::Config[:base_css_uri] + '/' + css_name + '.css'
    end

#TODO: augment with priority param when necessary
    def include_js(js_name)
      @js_includes << R8::Config[:base_js_uri] + '/' + js_name + '.js'
    end

    def add_js_exe(js_content)
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

#####################################################
    ### MAIN ACTION DEFS
#####################################################
    #TODO: remove parsed_query_string and instaed in action set split what really should go in uri and 
    #variables that pass @parsed_query_string
    def list(parsed_query_string=nil)
      @parsed_query_string = parsed_query_string 

#DEBUG
#SAVED SEARCH STUB
=begin
      search_params = ret_search_params_in_request()
      if !search_params.nil?
        saved_search["redirect"] = false
        save(saved_search)
      end
=end

      field_set = Model::FieldSet.default(model_name())

      where_clause = ret_where_clause()
      parent_id = ret_parent_id()
      order_by_list = ret_order_by_list() 
      paging_info = ret_paging_info()

      _model_var = {:i18n => get_model_i18n(model_name().to_s,user_context())}

#TODO: figure out clean way to seperate search out
#TODO hack that for testing, which no only implemented by node
      search_content = nil
      if model_name() == :node
        tpl = R8Tpl::TemplateR8.new("#{model_name()}/search",user_context())
        tpl.assign("_#{model_name().to_s}",_model_var)
tpl.assign(:saved_search_id,"foo")
        tpl.assign("#{model_name().to_s}_current_start",(paging_info||{})[:start]||0)
        tpl.assign(:_app,app_common())

        model = ret_model_for_list_search(field_set)
        tpl.assign("#{model_name().to_s}",model)
        search_content = tpl.render()
      end
#end search testing hack

#      if saved_search
#        tpl = R8Tpl::TemplateR8.new("saved_search/ss-"+saved_search["id"],user_context())
#        field_set = ret_ss_field_set(saved_search)
#      else
        tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{default_action_name()}",user_context())
#        field_set = Model::FieldSet.default(model_name())
#      end

      tpl.assign(:search_content, search_content)
      set_template_order_columns!(tpl,order_by_list,field_set)
      set_template_paging_info!(tpl,paging_info)

      opts = {:page => paging_info,:order_by => order_by_list}
#TODO: parent id is right now passed in opts, may change
      opts.merge!(:parent_id => parent_id) if parent_id

      model_list = get_objects(model_name(),where_clause,opts)
      tpl.assign("#{model_name().to_s}_list",model_list)

      tpl.assign("_#{model_name().to_s}",_model_var)

      tpl.assign(:_app,app_common())

      return {:content => tpl.render()}
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

      return {:content => tpl.render()}
    end
    ### end of main action defs

    #update or create depending on whether id is in post content
    def save(explicit_hash=nil)
      hash = explicit_hash || request.params.dup

      ### special fields
      id = hash.delete("id")
      parent_id = hash.delete("parent_id")
      parent_model_name = hash.delete("parent_model_name")
      model_name = hash.delete("model")
      name = hash.delete("name")
      redirect = (not (hash.delete("redirect").to_s == "false"))

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
        parent_id_handle = parent_id ? id_handle(parent_id,parent_model_name) : top_id_handle()
        hash.merge({:display_name => name})
        create_hash = {model_name.to_sym => {name => hash}}
        new_id = create_from_hash(parent_id_handle,create_hash)
        id=new_id if new_id
      end
      redirect "/xyz/#{model_name()}/display/#{id.to_s}" if redirect
    end

    def clone(id)
      hash = request.params
      target_id = nil
      target_id_handle = nil

      if hash["target_id"] and hash["target_model_name"]
#TODO: stub
        hash["target_model_name"] = "datacenter" if hash["target_model_name"] == "project"
        target_id = hash["target_id"].to_i
        target_id_handle = id_handle(target_id,hash["target_model_name"])
      #TODO: for testing
      elsif hash["target_uri"] and hash["obj"]
        c = ret_session_context_id()
        target_id_handle = IDHandle.new({:c => c, :uri => hash["target_uri"]},{:set_parent_model_name => true})
        target_id = target_id_handle.get_id()
      else
        Log.info("not implemented yet")
        return redirect "/xyz/#{model_name()}/display/#{id.to_s}"
      end

      new_id=Aux::benchmark("clone"){model_class.clone(id_handle(id),target_id_handle,{:ui=>request.params["ui"]})}
#      new_id = model_class.clone(id_handle(id),target_id_handle,{:ui=>request.params["ui"]})
      id = new_id if new_id

#TODO: clean this up,hack to update UI params for newly cloned object
#      update_from_hash(id,{:ui=>request.params["ui"]})

#      request.params["redirect"] ? redirect_route = "/xyz/#{request.params["redirect"]}/#{id.to_s}" : redirect_route = "/xyz/#{model_name()}/display/#{id.to_s}"

      if request.params["model_redirect"]
        base_redirect = "/xyz/"+request.params["model_redirect"] + "/" + request.params["action_redirect"]
        request.params["id_redirect"].match(/^\*/) ? redirect_id = id.to_s : redirect_id = request.params["id_redirect"]
        redirect_route = "#{base_redirect}/#{redirect_id}"
      else
        redirect_route = "/xyz/#{model_name()}/display/#{id.to_s}"
      end

      ajax_request? ? redirect_route += '.json' : nil
      redirect redirect_route
    end

   private
    def user_context()
      @user_context ||= UserContext.new(request,self.ajax_request?) #TODO: stub
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

#TODO: this is stubbed function, should return the field definitions for a give model
    def get_model_defs(model_name)
      model_def = Hash.new
    end

    def ret_session_context_id()
      #stub
      2
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
#for testing
require __DIR__('devtest')

#TODO: Should all controllers/models be loaded, or load just base, and rest dynamically

# Here go your requires for subclasses of Controller:
#require __DIR__('admin')
#require __DIR__('data_source')
%w{workspace action datacenter node_group node node_interface component attribute attribute_link monitoring_item saved_search}.each do |controller_file|
  require __DIR__(controller_file)
end


