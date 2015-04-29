module DTK
  class TargetController < AuthController
    helper :target_helper

    PROVIDER_PREFIX    = 'provider'
    PROVIDER_DELIMITER = ':::'

    def rest__list()
      subtype   = ret_target_subtype()
      parent_id = ret_request_params(:parent_id)

      response = 
        if subtype.eql? :instance
          opts = ((parent_id && !parent_id.empty?) ? { :filter => [:eq, :parent_id, parent_id]} : Hash.new)
          Target::Instance.list(model_handle(), opts)
        elsif subtype.eql? :template
          Target::Template.list(model_handle())
        else
          raise ErrorUsage.new("Illegal subtype param (#{subtype})")
        end
      rest_ok_response response
    end

    def rest__info()
      target = create_obj(:target_id, Target::Instance)
      rest_ok_response target.info(),:encode_into => :yaml
    end

    def rest__import_nodes()
      target = create_obj(:target_id, Target::Instance)
      #TODO: formatting to get right fields is done on client side now; should be done on server side
      #method Node::TargetRef:InventoryData.new can be removed or modified once that is done
      inventory_data_hash = ret_non_null_request_params(:inventory_data)
      inventory_data = Node::TargetRef::Input::InventoryData.new(inventory_data_hash)
      rest_ok_response Target::Instance.import_nodes(target, inventory_data)
    end

    def rest__install_agents()
      target = create_obj(:target_id)
      target.install_agents()
      rest_ok_response
    end

    def rest__create_install_agents_task()
      target = create_obj(:target_id)

      unmanaged_nodes = target.get_objs(:cols => [:unmanaged_nodes]).map{|r|r[:node]}
      return rest_ok_response if unmanaged_nodes.empty?

      opts = Hash.new
      if num_nodes = ret_request_params(:num_nodes)
        opts.merge!(:debug_num_nodes => num_nodes)
      end
      task = Task.create_install_agents_task(target,unmanaged_nodes,opts)
      task.save!()

      rest_ok_response :task_id => task.id
    end

    def rest__task_status()
      target = create_obj(:target_id)
      target_idh = target.id_handle()

      format = (ret_request_params(:format)||:hash).to_sym
      response = Task::Status::Target.get_status(target_idh,:format => format)
      rest_ok_response response
    end

    # create target instance
    def rest__create()
      provider        = create_obj(:provider_id, Target::Template)
      iaas_properties = ret_non_null_request_params(:iaas_properties).inject(Hash.new){|h,(k,v)|h.merge(k.to_sym => v)}
      target_type     = (ret_request_params(:type) || :ec2_classic).to_sym
      opts            = ret_params_hash(:target_name)
      project_idh     = get_default_project().id_handle()

      #TODO: for legacy: can be removed when clients upgraded
      iaas_properties[:region] ||= ret_request_params(:region)

      unless [:ec2_classic,:ec2_vpc].include?(target_type)
        raise ErrorUsage.new("Target type '#{target_type}' is not supported")
      end
      Target::Instance.create_target_ec2(project_idh, provider, target_type, iaas_properties, opts)
      rest_ok_response 
    end

    def rest__create_provider()
      iaas_type       = ret_non_null_request_params(:iaas_type)
      provider_name   = ret_non_null_request_params(:provider_name)
      iaas_properties = ret_request_params(:iaas_properties)
      params_hash     = ret_params_hash(:description)
      no_bootstrap    = ret_request_param_boolean(:no_bootstrap) || true

      project_idh  = get_default_project().id_handle()
      # setting :error_if_exists only if no bootstrap
      opts = {:raise_error_if_exists => no_bootstrap}
      provider = Target::Template.create_provider?(project_idh,iaas_type,provider_name,iaas_properties,params_hash,opts)
      response = {:provider_id => provider.id}

      # TODO: removing until provides for fact that need to know when ec2 whether vpc or classic 
      # unless no_bootstrap
      #  # select_region could be nil
      #  created_targets_info = provider.create_bootstrap_targets?(project_idh,selected_region)
      #  response.merge!(:created_targets => created_targets_info)
      # end
      rest_ok_response response 
    end

    def rest__delete_and_destroy()
      type = (ret_request_params(:type)|| :instance).to_sym # can be :instance or :template
      # TODO: stubbed now to have force being true; now only Target::Template.delete_and_destroy supports non force; so not passing in 
      # force param to Target::Instance.delete_and_destroy
      force = true
      response = {}
      case type
       when :template
        provider  = create_obj(:target_id, Target::Template)
        response = Target::Template.delete_and_destroy(provider,:force => force)
       when :instance
        target_instance = create_obj(:target_id, Target::Instance) 
        response = Target::Instance.delete_and_destroy(target_instance)
       else
        raise ErrorUsage.new("Illegal type '#{type}'")
      end
      rest_ok_response response
    end

    def rest__set_properties()
      target_instance = create_obj(:target_id, Target::Instance)
      iaas_properties = ret_request_params(:iaas_properties)
      Target::Instance.set_properties(target_instance, iaas_properties)
      rest_ok_response
    end

    def rest__set_default()
      target_instance = create_obj(:target_id, Target::Instance)
      update_workspace_target = true #TODO: stubbed might make this option passed by client
      Target::Instance.set_default_target(target_instance,:update_workspace_target => update_workspace_target)
      rest_ok_response
    end

    def rest__info_about()
      target = create_obj(:target_id)
      about = ret_non_null_request_params(:about).to_sym
      opts = ret_params_hash(:detail_level, :include_workspace)
      rest_ok_response target.info_about(about, opts)
    end


    def get_ports(id)
      target = create_object_from_id(id)
      port_list = target.get_ports("component_external","component_internal_external")
      return {:data=>port_list}
    end

    def get_nodes_status(id)
      target = create_object_from_id(id)
      nodes_status = target.get_and_update_nodes_status()
     # pp [:node_config_changes,target.get_node_config_changes()]

      return {:data=>nodes_status}
    end

    def edit
      
    end

    def display
      
    end

    def load_vspace(target_id)
      target = id_handle(target_id,:datacenter).create_object()
      target_id = target.id()

# TODO: how to retrieve fields from instance?
      target_hash = get_object_by_id(target_id,:datacenter)

# TODO: revisit when cleaning up toolbar, plugins and user settings
=begin
      tpl = R8Tpl::TemplateR8.new("workspace/notification_list",user_context())
      tpl.set_js_tpl_name("notification_list")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])
=end
      include_js('plugins/search.cmdhandler')
      view_space = {
        :type => 'datacenter',
        :i18n => 'Environments',
        :object => target_hash
      }
#      v_space_obj = JSON.generate(view_space)
#      run_javascript("R8.Workspace.pushViewSpace(#{v_space_obj});")

      #--------Setup Toolbar for access each group from ACL's---------
      #        add_js_exe("R8.Toolbar.init({node:'group-#{model_list[0][:id]}',tools:['quicksearch']});")
      user_has_toolbar_access = true
      user_group_tool_list = Array.new
      user_group_tool_list << 'quicksearch'
      toolbar_def = {:tools => user_group_tool_list}

      include_js('toolbar.quicksearch.r8')

      tpl_info_hash = Hash.new

      tpl = R8Tpl::TemplateR8.new("node_group/wspace_display",user_context())
      tpl.set_js_tpl_name("ng_wspace_display")
      tpl_info_hash[:node_group] = tpl.render()
      include_js_tpl(tpl_info_hash[:node_group][:src])

      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())
      tpl.set_js_tpl_name("node_wspace_display")
      tpl_info_hash[:node] = tpl.render()
      include_js_tpl(tpl_info_hash[:node][:src])

      tpl = R8Tpl::TemplateR8.new("datacenter/wspace_monitor_display",user_context())
      tpl.set_js_tpl_name("wspace_monitor_display")
      tpl_info_hash[:monitor] = tpl.render()
      include_js_tpl(tpl_info_hash[:monitor][:src])

      ##### ----------------- add in model info
      model_list = target.get_items()

      items = model_list.map do |object|
        object_id_sym = object.id.to_s.to_sym
        ui = ((dc_hash[:ui]||{})[:items]||{})[object_id_sym] || (object[:ui]||{})[target_id.to_s.to_sym]

        obj_tags = object[:display_name].split(',')
        model_name = object.model_name
        type = (obj_tags.include?("monitor")) ? :monitor : model_name
        {
          :type => type.to_s,
          :model => model_name.to_s,
          :object => object,
          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info_hash[type][:template_callback],
          :ui => ui,
          :tags => obj_tags
        }
      end
      view_space[:items] = items
      view_space_json = JSON.generate(view_space)
#      run_javascript("R8.Workspace.pushViewSpace(#{view_space_json});")
      run_javascript("R8.IDE.pushViewSpace(#{view_space_json});")


      #---------------------------------------------

      return {:data=>''}
    end

    def get_view_items(id)
      target = id_handle(id,:target).create_object()
      target_id = target.id()

      dc_hash = get_object_by_id(target_id,:target)

      view_space = {
        :type => 'datacenter',
        :i18n => 'Environments',
        :object => dc_hash
      }
      model_list = target.get_items()

      tpl_info_hash = {}
      tpl = R8Tpl::TemplateR8.new("node_group/wspace_display",user_context())
      tpl.set_js_tpl_name("ng_wspace_display")
      tpl_info_hash[:node_group] = tpl.render()

      tpl = R8Tpl::TemplateR8.new("node/wspace_display_ide",user_context())
      tpl.set_js_tpl_name("node_wspace_display_ide")
      tpl_info_hash[:node] = tpl.render()

      tpl = R8Tpl::TemplateR8.new("datacenter/wspace_monitor_display",user_context())
      tpl.set_js_tpl_name("wspace_monitor_display")
      tpl_info_hash[:monitor] = tpl.render()

      items = model_list.map do |object|
        object_id_sym = object.id.to_s.to_sym
        ui = ((dc_hash[:ui]||{})[:items]||{})[object_id_sym] || (object[:ui]||{})[target_id.to_s.to_sym]

        obj_tags = object[:display_name].split(',')
        model_name = object.model_name
        type = (obj_tags.include?("monitor")) ? :monitor : model_name
        {
          :type => type.to_s,
          :model => model_name.to_s,
          :object => object,
#          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info_hash[type][:template_callback],
          :ui => ui,
          :tags => obj_tags
        }
      end
      view_space[:items] = items
#      view_space_json = JSON.generate(view_space)
#      run_javascript("R8.Workspace.pushViewSpace(#{view_space_json});")

      return {:data=>view_space}
    end

    def create()
      # TODO: Should we remove this method?
      return {}
    end

    def add_item(id)
      # TODO: need to copy in avatar when hash["ui"] is non null
      target = id_handle(id).create_object()

      override_attrs = request.params["ui"] ? {:ui=>request.params["ui"]} : {}

      model_id_handle = id_handle(request.params["model_id"].to_i,request.params["model"].to_sym)
      if request.params["model"] == "node"
        node_binding_rs =  create_object_from_id(request.params["model_id"],:node_binding_ruleset)
        new_item_id = node_binding_rs.clone_or_match(target).get_id()
      else
        new_item_id = target.add_item(model_id_handle,override_attrs)
      end
# TODO: how do we get field info from model instance?
      dc_hash = get_object_by_id(id,:datacenter)
      dc_ui = dc_hash[:ui].nil? ? {:items=>{}} : dc_hash[:ui]
# TODO: cleanup later, right now ui req param indexed by dc id from old style
      ui_params = JSON.parse(request.params["ui"])
#      dc_ui[:items][new_item_id.to_s.to_sym] = ui_params[id.to_s]
      dc_ui[:items][new_item_id.to_s.to_sym] = ui_params[id]
# TODO: any way to update a model from its object once an instance is created?
      update_from_hash(id,{:ui=>dc_ui})


# pp '++++++++++++++++++++++++++++++++++++++'
# pp 'SHOULD HAVE UPDATED FROM HASH FOR TARGET OBJECT:'
# pp dc_ui

# TODO: clean this up,hack to update UI params for newly cloned object
#      update_from_hash(id,{:ui=>hash["ui"]})

#      hash["redirect"] ? redirect_route = "/xyz/#{hash["redirect"]}/#{id.to_s}" : redirect_route = "/xyz/#{model_name()}/display/#{id.to_s}"

      if request.params["model_redirect"]
        base_redirect = "/xyz/#{request.params["model_redirect"]}/#{request.params["action_redirect"]}"
        redirect_id =  request.params["id_redirect"].match(/^\*/) ? new_item_id.to_s : request.params["id_redirect"]
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
        redirect_route = "/xyz/#{model_name()}/display/#{new_item_id.to_s}"
        ajax_request? ? redirect_route += '.json' : nil
      end

      redirect redirect_route
    end

    def get_links(id)
      target = id_handle(id,:datacenter).create_object()
      item_list = JSON.parse(request.params["item_list"])
      item_list = item_list.reject do |x|
        Log.error("get links missing needed params") unless x["id"] and x["model"]
      end
# TODO: move this call into underlying get_links call,
      item_list = item_list.map{|x|id_handle(x["id"].to_i,x["model"].to_sym)}
# TODO: make get_links an instance method, should pull all links from children if item_list is []/nil
      raise Error.new("Target::get_ports_links is deprecated")
      link_list = target.class.get_port_links(item_list,"component_external")
      return {'data'=>link_list}
    end

    def get_warnings(id)
      datacenter = get_object_by_id(id,:datacenter)
      notification_list = datacenter.get_violation_info("warning")
      notification_list.each_with_index do |n,index|
        notification_list[index][:type] = "warning"
      end
# DEBUG
# pp [:warnings,notification_list]
      return {:data=>notification_list}
    end

  end
end
