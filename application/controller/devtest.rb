module XYZ
  class DevtestController < AuthController 
    #using default layout
    layout :default
    def initialize
      super
      @content = nil
    end
    def dev_test
      @content
    end

    def chef_test
      json_attrs = nil
      File.open("/root/node.json"){|f| json_attrs  =f.read}
      json_attrs
    end

    def discover_and_update(*uri_array)
      c = ret_session_context_id()
      ds_type = uri_array.shift.to_sym
      container_uri = "/" + uri_array.join("/")
      ds_uri =  "#{container_uri}/data_source/#{ds_type}"
      parent_id = ret_id_from_uri(ds_uri)
      raise Error.new("cannot find #{ds_uri}") if parent_id.nil?
      ds_object_objs = Model.get_objects(ModelHandle.new(c,:data_source_entry), nil, :parent_id => parent_id)
      raise Error.new("cannot find any #{ds_type} data source objects in #{container_uri}") if ds_object_objs.empty?
      #so that cache can be shared accross different ds_object_objs
      #TODO make more sophisticated
      common_ds_connectors = Hash.new 
      ds_object_objs.each{|x|x.set_and_share_ds_connector!(common_ds_connectors,container_uri)}
      ds_object_objs.each{|x|x.discover_and_update()}
      DataSource.set_collection_complete(IDHandle[:c => c, :uri => ds_uri])
      redirect "xyz/node/list"    #TODO: just hack where redirect is
    end

    def list(*uri_array)
      error_405 unless request.get?
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string_from_uri()
      opts[:no_hrefs] ||= true
      opts[:depth] ||= :deep
      opts[:no_null_cols] = true
      href_prefix = "http://" + http_host() + "/list" 
      c = ret_session_context_id()
      @title = uri
      id_handle = IDHandle[:c => c,:uri => uri]
      objs = Object.get_instance_or_factory(IDHandle[:c => c,:uri => uri],href_prefix,opts)
      #TBD: implement :normalized_attrs_only flag
      @results = objs
    end
################################################################################
################################################################################
################################################################################

#TODO: move out of here
    ACTION_HANDLER_IS_ASYNCHRONOUS = {
#      :import_chef_recipes => true
    }

    #TODO: might refactor other actions to use this
    #TODO: want to route to this, not allow direct call; how can we enforce this (maybe route with this prefix leads to unauthorized
    ACTION_HANDLER_OBJ = {
      :import_chef_recipes => Library,
      :clone_component => Object,
      :discover_nodes => Target,
      :update_from_hash => Object,
      :create_attribute_link => AttributeLink,
      :create_simple => Object,
      :delete => Object
#      :encapsulate_elements_in_project => Project
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

    #TODO: starting to bring in new code; hard coded just for list_components
    def test__list(*uri_array)
      error_405 unless request.get?
      action = ViewAction::ListObjects
      uri = "/" + uri_array.join("/")
      http_opts = ret_parsed_query_string_from_uri()
      href_prefix = "http://" + http_host() + "/list"
      c = ret_session_context_id()
      
      result_array = ActionSet::Singleton.dispatch_action(action,c,uri,href_prefix,http_opts)
      print JSON.pretty_generate(result_array) # stub
      #TODO: put in rendering
    end

    #TODO: starting to bring in new code; hard coded just for import_chef_recipes
    def action_handler__import_chef_recipes(*uri_array)
      error_405 unless request.post?
      action = :import_chef_recipes
      uri = request[:library_uri]
      opts = ret_parsed_query_string_from_uri()
      href_prefix = "http://" + http_host() + "/list"
      c = ret_session_context_id()
      result_array = ActionSet::ImportChefRecipes.dispatch_actions(c,uri,request,href_prefix,opts)
      print JSON.pretty_generate(result_array) # stub
      redirect_uri = uri
      redirect route('list/' + redirect_uri) unless redirect_uri.nil?
    end

#TODO: move out of here and modularize

    #TODO: this fn getting too large; will modularize 
    def action_handler(action_x,*uri_array)
      error_405 unless request.post?
      action = action_x.to_sym
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string_from_uri()
      href_prefix = "http://" + http_host() + "/list"
      c = ret_session_context_id()

      task = Task.create(ACTION_HANDLER_IS_ASYNCHRONOUS[action] ? c : nil)
      redirect_uri = task[:uri] 

      #TODO: stubbing how variables obj, params, and redirect_uri set (would make this data driven; casing on action)
      obj = ACTION_HANDLER_OBJ[action]
      #TODO: wil replace with data driven logic
      params = nil; opts_added = nil
      #TODO: what parameters below correspond to is getting obscurred so might have each action in model take one paramter which is a hash and then effect we can specific "call by value" 
      case action
        when :import_chef_recipes
      	  params = [
              IDHandle[:c=> c,
              :uri => request[:library_uri]],
	            request[:cookbooks_uri]
          ]
          redirect_uri ||= request[:library_uri]
        when :update_from_hash
          #TODO: had problem with restclients encoding of nils/nulls in hash; so sending json as hash attribute
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
            IDHandle[:c => c,:uri => request[:datacenter_uri]],
            request[:discover_mode_info]
          ]
          redirect_uri = request[:datacenter_uri]
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
          #TODO: error if request[:uri] is null
          params = [request[:uri],c]
          redirect_uri ||= request[:uri]
        when :delete
          #TODO: error if request[:uri] is null
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

      user_object  = ::DTK::CurrentSession.new.user_object()
      #dispatcher line
      if ACTION_HANDLER_IS_ASYNCHRONOUS[action]
        CreateThread.defer_with_session(user_object) {
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

    #TODO: just temp; may want the rest uris to mirror the ui ones; ideally whether rest or ui request handled by same actions, difference just is in opts passed
    def rest(*uri_array)
      error_405 unless request.get?
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string_from_uri()
      href_prefix = "http://" + http_host() + "/rest"
      c = ret_session_context_id()
      @results = Object.get_instance_or_factory(IDHandle[:c => c,:uri => uri],href_prefix,opts)
    end

#TODO: move out of here
    def library__public
     error_405 unless request.get?
     uri = "/library/public" 
     opts = ret_parsed_query_string_from_uri()
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
      opts = ret_parsed_query_string_from_uri()
      c = ret_session_context_id()
      @title = "List from Guid"
      @results = Object.get_instance_or_factory(IDHandle[:c => c,:guid => guid],href_prefix,opts)
    end

    #TODO: temp
    def list_contained_attributes(*uri_array)
      error_405 unless request.get? 
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string_from_uri()
      type = opts[:value_type] || :value
      error_405 unless [:derived,:asserted,:value].include?(type)
      c = ret_session_context_id()
      @results = Object.get_contained_attributes(type,IDHandle[:c => c,:uri => uri])
    end

#TODO: move out of here
    #TODO: temp
    def list_node_attributes(*uri_array)
      error_405 unless request.get? 
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string_from_uri()
      c = ret_session_context_id()
      @results = Node.get_node_attribute_values(IDHandle[:c => c,:uri => uri],opts)
    end

#TODO: move out of here, this seems to belong in the central model handler
    #TODO: temp
    def get_guid(*uri_array)
      error_405 unless request.get? 
      uri = "/" + uri_array.join("/")
      c = ret_session_context_id()
      @results = Object.get_guid(IDHandle[:c => c,:uri => uri])
    end

##################################

    def testing
      return "anything reaching this route"
    end
  end
end
