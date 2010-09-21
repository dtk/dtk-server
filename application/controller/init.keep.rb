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
    include R8Tpl::CommonMixin
    include R8Tpl::Utility::I18n

    provide(:html, :type => 'text/html'){|a,s|s} #lamba{|a,s|s} is fn called after bundle and render for a html request
#    provide(:json, :type => 'application/json'){|a,s| JSON.pretty_generate(s) }   
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

      @css_includes = Array.new
      @js_includes = Array.new

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
            @ctrl_results[action_namespace][:js_includes].each { |js_include| include_js(js_include) }
          end
          if !@ctrl_results[action_namespace][:css_includes].nil?
            @ctrl_results[action_namespace][:css_includes].each { |css_include| include_css(css_include) }
          end
  
          #TODO: process js_exe_scripts
        end

        #set template vars
        _app = {
          :js_includes => @js_includes,
          :css_includes => @css_includes,
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
#TODO: nothing here yet
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


#####################################################
    ### MAIN ACTION DEFS
#####################################################

    #TODO: need to figure out best way to handle parsed_query_string
    def list(parsed_query_string=nil)
#tpl = nil
#require 'benchmark'
# puts Benchmark.measure {
      where_clause = parsed_query_string
      #default is partial match
      #TODO: move to more general place
      if where_clause
        where_clause = where_clause.inject(nil){|h,o|SQL.and(h,SQL::WhereCondition.like(o[0],"#{o[1]}%"))}
      end
      start = 0
      limit = R8::Config[:page_limit] || 20
      order_by = nil
      opts = {:page => {:start => start, :limit => limit},:order_by => order_by}
      model_list = get_objects(model_name(),where_clause,opts)

      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{default_action_name()}",user_context())
      tpl.assign("#{model_name().to_s}_list",model_list)
      #TODO: needed to below back in so template did not barf
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)
 # }
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

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
    def save
      hash = request.params.dup

      ### special fields
      id = hash.delete("id")
      parent_id = hash.delete("parent_id")
      parent_model_name = hash.delete("parent_model_name")
      model_name = hash.delete("model")
      name = hash.delete("name")

      #TODO: fix up encapsulate translating from raw_hash to one for model
      all_actual_cols = Model::FieldSet.all_actual(model_name)
      hash.each do |k,v|
        unless all_actual_cols.include?(k.to_sym) and hash[k] and not hash[k].empty?
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
        new_id=create_from_hash(parent_id_handle,create_hash)
        id=new_id if new_id
      end
      redirect "/xyz/#{model_name()}/display/#{id.to_s}"
    end

    def clone(id)
      hash = request.params
      target_id_handle = nil
      if hash["target_id"] and hash["target_model_name"]
        target_id_handle = id_handle(hash["target_id"],hash["target_model_name"])
      elsif hash["target_uri"] #TODO: just testing stub
        target_uri = hash["target_uri"]
        c = ret_session_context_id()
        Model.create_simple_instance?(target_uri,c,:recursive_create => true)
        target_id_handle = IDHandle[:c => c, :uri => target_uri]        
      else
        Log.info("not implemented yet")
        return redirect "/xyz/#{model_name()}/display/#{id.to_s}"
      end

      new_id = clone_to_target(id_handle(id),target_id_handle)
      id = new_id if new_id

      request.params["redirect"] ? redirect_route = "/xyz/#{request.params["redirect"]}/#{id.to_s}" : redirect_route = "/xyz/#{model_name()}/display/#{id.to_s}" 

      ajax_request? ? redirect_route += '.json' : nil
pp request.params
pp redirect_route
#return;
      redirect redirect_route
    end

   private
    def user_context()
      @user_context ||= UserContext.new(request,self.ajax_request?) #TODO: stub
    end

    ######################
    #####Helper fns
#TODO: this shouldnt be a controller method, tied to models
    def get_objects(model_name,where_clause={},opts={})
      c = ret_session_context_id()
      field_set = opts[:field_set] || default_field_set(model_name)
      #returns any related tables that must be joined in (by looking at virtual coumns)
      related_columns = Model::FieldSet.related_columns(field_set,model_name)
      ret = nil
      unless related_columns
        ret = Model.get_objects(ModelHandle.new(c,model_name),where_clause,opts)
      else
        ls_opts = opts.merge :field_set => field_set
        graph_ds = Model.get_objects_just_dataset(ModelHandle.new(c,model_name),where_clause,ls_opts)
        related_columns.each do |mod,join_array|
          join_array.each do |join_info|
            rs_opts = (join_info[:cols] ? {:field_set => join_info[:cols]} : {}).merge :return_as_hash => true
            right_ds = Model.get_objects_just_dataset(ModelHandle.new(c,mod),nil,rs_opts)
            graph_ds = graph_ds.graph(:left_outer,right_ds,join_info[:join_cond])
          end
        end
        ret = graph_ds.all
      end
      ret
    end

    def get_object_by_id(id)
      get_objects(model_name,{:id => id}).first

#TODO removed below; need to modify or remove to handle virtual columns
#      Model.get_object(id_handle(id))
    end

    def update_from_hash(id,hash)
      opts = Hash.new
      Model.update_from_hash_assignments(id_handle(id),Aux.ret_hash_assignments(hash),opts)
    end

    def create_from_hash(parent_id_handle,hash)
      opts = Hash.new
      #TODO modify create_from_hash so directly returns id and we dont have to translate from uri
      new_uri = Model.create_from_hash(parent_id_handle,hash,nil,opts).first
      new_id = ret_id_from_uri(new_uri)
      Log.info("created new object with uri #{new_uri} and id #{new_id}") if new_id
      new_id
    end

    def clone_to_target(id_handle,target_id_handle)
      opts = Hash.new
      #TODO modify clone so directly returns id and we dont have to translate from uri
      new_uri = Model.clone(id_handle,target_id_handle,opts).first
      new_id = ret_id_from_uri(new_uri)
      Log.info("created new object with uri #{new_uri} and id #{new_id}") if new_id
      new_id
    end

    def id_handle(id,i_model_name=model_name())
      c = ret_session_context_id()
      IDHandle[:c => c,:guid => id.to_i, :model_name => i_model_name.to_sym]
    end

    def top_id_handle()
      c = ret_session_context_id()
      IDHandle[:c => c,:uri => "/"]
    end

    def ret_id_from_uri(uri)
      return nil if uri.nil?
      c = ret_session_context_id()
      id_info = IDInfoTable.get_row_from_id_handle(IDHandle[:c => c, :uri => uri])
      id_info ? id_info[:id] : nil
    end

    ################
   def default_action_name
     this_parent_method.to_sym
   end

   def model_name
      @model_name ||= Aux.demodulize(self.class.to_s).gsub(/Controller$/,"").downcase.to_sym
   end

   def default_field_set(m=nil)
     Model::FieldSet.default(m||model_name())
   end

    def ret_session_context_id()
      #stub
      2
    end

    def ret_parsed_query_string()
#TODO: can we make the request params an instance variable of the controller
      opts = {}
      #TBD: not yet looking for errors in the query string
      request.env["QUERY_STRING"].scan(%r{([/A-Za-z0-9_]+)=([/A-Za-z0-9_]+)}) {
        key = $1.to_sym
        value = $2
        if value == "true" 
          opts[key] = true
        elsif value == "false"
          opts[key] = false
        elsif value =~ /^[0-9]+$/
          opts[key] = value #should be converted into an integer
        else
          opts[key] = value
       #TODO find where value shoudl be sym   opts[key] = value.to_sym
        end #TBD: not complete; for example not for decimals
      }
      opts
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

#TODO: Should all controllers/models be loaded, or load just base, and rest dynamically

# Here go your requires for subclasses of Controller:
#require __DIR__('admin')
require __DIR__('workspace')
require __DIR__('project')
#require __DIR__('data_source')
require __DIR__('node')
require __DIR__('component')
require __DIR__('attribute')
require __DIR__('attribute_link')

require __DIR__('devtest')

# system fns for controller
require __DIR__('action_set')
