#require File.expand_path('swoop_stub', File.dirname(__FILE__))
#require File.expand_path('frontend_integration_stub', File.dirname(__FILE__))

require File.expand_path('workspace', File.dirname(__FILE__))

#TBD: stub; will move to own file and will populate from web call
module XYZ
  class UserContext
    attr_reader :current_profile
    def initialize()
      @current_profile = :default
    end
  end
end

 # Default url mappings are:
#  a controller called Main is mapped on the root of the site: /
#  a controller called Something is mapped on: /something
# If you want to override this, add a line like this inside the class
#  map '/otherurl'
# this will force the controller to be mounted on: /otherurl

module XYZ
  class MainController < Controller

    # TBD instead having class AppController < Controller would be equaivalent to asserting map /xyz/app (when insider xyz namespace)
=begin  
  layout do |path,wish| 
      if wish == "html"
        path == "actset__main" or path == "swoop" ? nil : :default
      end
    end
=end
    def index
      layout :test
    end

    ####### helper functions; make private and move to diff position in file
    def field_set()
      self.class.field_set()
    end

    ########
    def list

      where_clause = ret_parsed_query_string()
      #getting model_name by looking at self.class, (e.g., self.class can = XYZ::NodeController)
      model_name = Aux.demodulize(self.class.to_s).gsub(/Controller$/,"").downcase
      model_list = get_objects(model_name.to_sym,field_set,where_clause)
      action_name = :list #TBD: automatically determine this

      user_context = UserContext.new #TBD: stub
      tpl = R8Tpl::TemplateR8.new(model_name,action_name,user_context)
      tpl.set_view()

#not quite sure what was happening here, but assign should always be name=>value assignments
      tpl.assign("#{model_name}_list",model_list)
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)

      ctrl_result = {
        :tpl_contents => tpl.render(nil,false) #nil, false args for testing
      }
    end

    def display(id)
      model_name = Aux.demodulize(self.class.to_s).gsub(/Controller$/,"").downcase
      model_result = get_object_by_id(id)
pp  model_result
      action_name = :display #TBD: automatically determine this
      user_context = UserContext.new #TBD: stub
      tpl = R8Tpl::TemplateR8.new(model_name,action_name,user_context)
      tpl.set_view()

#not quite sure what was happening here, but assign should always be name=>value assignments
      tpl.assign(model_name.to_sym,model_result)

      ctrl_result = {
        :tpl_contents => tpl.render(nil,false) #nil, false args for testing
      }
    end


    def edit
      id = retrieve_from_route
      model = model_name.to_s
      model_result = get_object_by_id(id,model)

      action_name = :edit #TBD: automatically determine this
      #set the view name to the model view folder and list view
      view_name = model+'/'+action_name.to_s
      tpl.set_view(view_name)

      tpl.assign(model,model_result)

      ctrl_result = {
        :tpl_contents => tpl.render()
      }
    end

################################################################################
################################################################################
################################################################################
#TODO; below are just needed for testing and will be removed later
    ACTION_HANDLER_IS_ASYNCHRONOUS = {
#      :import_chef_recipes => true
    }


    #TBD: might refactor other actions to use this
    #TBD: want to route to this, not allow direct call; how can we enforce this (maybe route with this prefix leads to unauthorized
    ACTION_HANDLER_OBJ = {
      :import_chef_recipes => Library,
      :clone_component => Object,
      :discover_nodes => Deployment,
      :update_from_hash => Object,
      :create_attribute_link => AttributeLink,
      :create_node_component_assoc => AssocNodeComponent,
      :create_simple => Object,
      :delete => Object,
      :encapsulate_elements_in_project => Project
    }

    ACTION_HANDLER_METHOD_NAME = {
      :import_chef_recipes => :import_chef_recipes,
      :clone_component => :clone,
      :discover_nodes => :discover_nodes,
      :update_from_hash => :update_from_hash,
      :create_attribute_link => :create,
      :create_node_component_assoc => :create,
      :create_simple => :create_simple,
      :delete => :delete,
      :encapsulate_elements_in_project =>  :encapsulate_elements_in_project
    }


##################################

    #TBD: starting to bring in new code; hard coded just for list_components
    def test__list(*uri_array)
      error_405 unless request.get?
      action = ViewAction::ListObjects
      uri = "/" + uri_array.join("/")
      http_opts = ret_parsed_query_string()
      href_prefix = "http://" + http_host() + "/list"
      c = ret_session_context_id()
      
      result_array = ActionSet::Singleton.dispatch_action(action,c,uri,href_prefix,http_opts)
      print JSON.pretty_generate(result_array) # stub
      #TBD: put in rendering
    end

#TODO: move out of here
    #TBD: starting to bring in new code; hard coded just for import_chef_recipes
    def action_handler__import_chef_recipes(*uri_array)
      error_405 unless request.post?
      action = :import_chef_recipes
      uri = request[:library_uri]
      opts = ret_parsed_query_string()
      href_prefix = "http://" + http_host() + "/list"
      c = ret_session_context_id()
      result_array = ActionSet::ImportChefRecipes.dispatch_actions(c,uri,request,href_prefix,opts)
      print JSON.pretty_generate(result_array) # stub
      redirect_uri = uri
      redirect route('list/' + redirect_uri) unless redirect_uri.nil?
    end

#TODO: move out of here and modularize

    #TBD: this fn getting too large; will modularize 
    def action_handler(action_x,*uri_array)
      error_405 unless request.post?
      action = action_x.to_sym
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string()
      href_prefix = "http://" + http_host() + "/list"
      c = ret_session_context_id()

      task = Task.create(ACTION_HANDLER_IS_ASYNCHRONOUS[action] ? c : nil)
      redirect_uri = task[:uri] 

      #TBD: stubbing how variables obj, params, and redirect_uri set (would make this data driven; casing on action)
      obj = ACTION_HANDLER_OBJ[action]
      #TBD: wil replace with data driven logic
      params = nil; opts_added = nil
      #TBD: what parameters below correspond to is getting obscurred so might have each action in model take one paramter which is a hash and then effect we can specific "call by value" 
      case action
        when :import_chef_recipes
      	  params = [
              IDHandle[:c=> c,
              :uri => request[:library_uri]],
	            request[:cookbooks_uri]
          ]
          redirect_uri ||= request[:library_uri]
        when :update_from_hash
          #TBD: had problem with restclients encoding of nils/nulls in hash; so sending json as hash attribute
          params = [
            IDHandle[:c => c,:uri => uri],
            JSON.parse(request[:content])
          ]
          redirect_uri = uri
        when :clone_component
          params = [
            IDHandle[:c => c,:uri => request[:source_component_uri]],
            IDHandle[:c => c, :uri => request[:target_project_uri]],
            :component,
            nil
          ]
          redirect_uri = request[:target_project_uri]
        when :discover_nodes
          params = [
            IDHandle[:c => c,:uri => request[:deployment_uri]],
            request[:discover_mode_info]
          ]
          redirect_uri = request[:deployment_uri]
        when :create_attribute_link
          params = [
            IDHandle[:c => c, :uri => request[:target_uri]],
            IDHandle[:c => c, :uri => request[:input_endpoint_uri]],
            IDHandle[:c => c, :uri => request[:output_endpoint_uri]],
            href_prefix
          ]
          redirect_uri ||= request[:target_uri]
        when :create_node_component_assoc
          params = [
            IDHandle[:c => c, :uri => request[:target_uri]],
	          IDHandle[:c => c, :uri => request[:node_uri]],
	          IDHandle[:c => c, :uri => request[:component_uri]],
            href_prefix
          ]
          redirect_uri ||= request[:target_uri]
        when :create_simple
          #TBD: error if request[:uri] is null
          params = [request[:uri],c]
          redirect_uri ||= request[:uri]
        when :delete
          #TBD: error if request[:uri] is null
          params = [
            IDHandle[:c=> c, :uri => request[:uri]],
            (opts ? opts : {}).merge({:task => task})
          ]
          opts_added = true
          instance_ref,factory_uri = RestURI.parse_instance_uri(request[:uri])
          redirect_uri ||= factory_uri
        when :encapsulate_elements_in_project
          params = [
            IDHandle[:c => c, :uri => request[:project_uri]],
            request[:new_component_uri]
          ]
          redirect_uri ||= request[:project_uri]
      end

      raise XYZ::Error.new("illegal action request") if obj.nil? or params.nil? or redirect_uri.nil?
      ##last arg is opts
      params << {:task => task} unless opts_added

      #dispatcher line
      if ACTION_HANDLER_IS_ASYNCHRONOUS[action]
        Ramaze.defer{
          begin
            obj.send(ACTION_HANDLER_METHOD_NAME[action] || action,*params)
            task.update_status(:complete) 
          rescue Exception => err
            task.add_error_toplevel(err) if err.kind_of?(Error)
            task.update_status(:error)
          end
        }
      else
        obj.send(ACTION_HANDLER_METHOD_NAME[action] || action,*params)
      end

      redirect route('list_temp/' + redirect_uri) unless redirect_uri.nil?
    end

    #TBD: just temp; may want the rest uris to mirror the ui ones; ideally whether rest or ui request handled by same actions, difference just is in opts passed
    def rest(*uri_array)
      error_405 unless request.get?
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string()
      href_prefix = "http://" + http_host() + "/rest"
      c = ret_session_context_id()
      @results = Object.get_instance_or_factory(IDHandle[:c => c,:uri => uri],href_prefix,opts)
    end

#TODO: move out of here
    def library__public
     error_405 unless request.get?
     uri = "/library/public" 
     opts = ret_parsed_query_string()
     href_prefix = "http://" + http_host() + "/list"
     c = ret_session_context_id()
     @results = Object.get_instance_or_factory(IDHandle[:c => c,:uri => uri],href_prefix,opts)
     @title = uri
    end

#TODO: move out of here, this doesnt belong in the controller
    # for list from id  
    def list_by_guid(guid)
      error_405 unless request.get? 
      href_prefix = "http://" + http_host() + "/list" 
      opts = ret_parsed_query_string()
      c = ret_session_context_id()
      @title = "List from Guid"
      @results = Object.get_instance_or_factory(IDHandle[:c => c,:guid => guid],href_prefix,opts)
    end

    #TBD: temp
    def list_contained_attributes(*uri_array)
      error_405 unless request.get? 
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string()
      type = opts[:value_type] || :value
      error_405 unless [:derived,:asserted,:value].include?(type)
      c = ret_session_context_id()
      @results = Object.get_contained_attributes(type,IDHandle[:c => c,:uri => uri])
    end

#TODO: move out of here
    #TBD: temp
    def list_node_attributes(*uri_array)
      error_405 unless request.get? 
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string()
      c = ret_session_context_id()
      @results = Node.get_node_attribute_values(IDHandle[:c => c,:uri => uri],opts)
    end

#TODO: move out of here, this seems to belong in the central model handler
    #TBD: temp
    def get_guid(*uri_array)
      error_405 unless request.get? 
      uri = "/" + uri_array.join("/")
      c = ret_session_context_id()
      @results = Object.get_guid(IDHandle[:c => c,:uri => uri])
    end

#TODO: just temp
#Generic list example is above
    def list_temp(*uri_array)
      error_405 unless request.get?
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string()
      opts[:no_hrefs] ||= true
      opts[:depth] ||= :deep
      opts[:no_null_cols] = true
      href_prefix = "http://" + http_host() + "/list" 
      c = ret_session_context_id()
      @title = uri
      objs = Object.get_instance_or_factory(IDHandle[:c => c,:uri => uri],href_prefix,opts)
require 'pp'; pp objs
      @results = objs
    end

    # the string returned at the end of the function is used as the html body
    # if there is no template for the action. if there is a template, the string
    # is silently ignored
    def notemplate
      "there is no 'notemplate.xhtml' associated with this action"
    end
  end
end

#TODO: move out of here, routes should be moved to routes config file

#examples of routes
Ramaze::Route['/list_recipes'] = '/list/library/public'

Ramaze::Route[ 'rest request' ] = lambda{ |path, request|
    if path =~ %r{(/rest/.+$)}
      uri = $1
      uri + '.json' unless path =~ %r{\.[A-Za-z0-9_]+$}
    end  
}
