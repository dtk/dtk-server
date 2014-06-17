module XYZ
  class DatacenterController < AuthController
    def create(name)
      c = ret_session_context_id()
      Target.create(name,c)
      "target created with name #{name}"
    end

    def get_warnings(id)
      datacenter = get_object_by_id(id)
      notification_list = datacenter.get_violation_info("warning")
      notification_list.each_with_index do |n,index|
        notification_list[index][:type] = "warning"
      end
# DEBUG
# pp [:warnings,notification_list]
      return {:data=>notification_list}
    end

    def load_vspace(datacenter_id)
      datacenter = id_handle(datacenter_id,:datacenter).create_object()
      datacenter_id = datacenter.id()

# TODO: how to retrieve fields from instance?
      dc_hash = get_object_by_id(datacenter_id,:datacenter)

# TODO: revisit when cleaning up toolbar, plugins and user settings
      tpl = R8Tpl::TemplateR8.new("workspace/notification_list",user_context())
      tpl.set_js_tpl_name("notification_list")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      include_js('plugins/search.cmdhandler')
      view_space = {
        :type => 'datacenter',
        :i18n => 'Environments',
        :object => dc_hash
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
      model_list = datacenter.get_items()

      items = model_list.map do |object|
        object_id_sym = object.id.to_s.to_sym
        ui = ((dc_hash[:ui]||{})[:items]||{})[object_id_sym] || (object[:ui]||{})[datacenter_id.to_s.to_sym]

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
      run_javascript("R8.Workspace.pushViewSpace(#{view_space_json});")


      #---------------------------------------------

      return {
        :content => '',
        :panel => 'viewspace'
      }
    end

    def update_vspace_ui(id)
# TODO: not used      dc_hash = get_object_by_id(id,:datacenter)
# pp '*******UPDATING VSPACE UI***************'
# pp request.params
      update_from_hash(id,{:ui=>JSON.parse(request.params["ui"])})
#      update_from_hash(id,{:ui=>JSON.parse(request.params["ui"])}) if request.params["ui"].kind_of?(Hash)
      return {}
    end

    def add_item(id)
      # TODO: need to copy in avatar when hash["ui"] is non null
      target = id_handle(id).create_object()

      override_attrs = request.params["ui"] ? {:ui=>request.params["ui"]} : {}

      model_id_handle = id_handle(request.params["id"].to_i,request.params["model"].to_sym)
      new_item_id = target.add_item(model_id_handle,override_attrs)
#      id = new_id if new_id

# TODO: how do we get field info from model instance?
      dc_hash = get_object_by_id(id,:datacenter)
      dc_ui = dc_hash[:ui].nil? ? {:items=>{}} : dc_hash[:ui]
# TODO: cleanup later, right now ui req param indexed by dc id from old style
      ui_params = JSON.parse(request.params["ui"])
      dc_ui[:items][new_item_id.to_s.to_sym] = ui_params[id.to_s]
# TODO: any way to update a model from its object once an instance is created?
      update_from_hash(id,{:ui=>dc_ui})

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

    # TODO: is this deprecated
    def get_links(id)
      datacenter = id_handle(id,:datacenter).create_object()
      item_list = JSON.parse(request.params["item_list"])
      item_list = item_list.reject do |x|
        Log.error("get links missing needed params") unless x["id"] and x["model"]
      end
# TODO: move this call into underlying get_links call,
      item_list = item_list.map{|x|id_handle(x["id"].to_i,x["model"].to_sym)}
# TODO: make get_links an instance method, should pull all links from children if item_list is []/nil
      link_list = datacenter.class.get_port_links(item_list,"component_external")
      return {'data'=>link_list}
    end

    def wspace_edit
      tpl = R8Tpl::TemplateR8.new("datacenter/wspace_edit",user_context())
      tpl.assign(:_app,app_common())
      tpl.assign(:submit_label,"Create Target")
      panel_id = request.params['panel_id']

      include_js('plugins/environment.tool')
#      run_javascript('setTimeout(initUserForm,500);')
      run_javascript('R8.EnvironmentTool.init();')

      return {
        :content=> tpl.render(),
        :panel=>panel_id
      }
    end

  end
end
