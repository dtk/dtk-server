module XYZ
  class DatacenterController < Controller
    def create(name)
      c = ret_session_context_id()
      Datacenter.create(name,c)
      "datacenter created with name #{name}"
    end

    def load_vspace(datacenter_id)
      datacenter = id_handle(datacenter_id,:datacenter).create_object()
      datacenter_id = datacenter.id()

      include_js('plugins/search.cmdhandler')
      view_space = {
        :type => 'datacenter',
        :object => datacenter
      }
      v_space_obj = JSON.generate(view_space)
      run_javascript("R8.Workspace.pushViewSpace(#{v_space_obj});")

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

      ##### ----------------- add in model info
      model_list = datacenter.get_items()

      items = model_list.map do |object|
        model_name = object.model_name
        {
          :type => model_name.to_s,
          :object => object,
          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info_hash[model_name][:template_callback],
          :ui => object[:ui][datacenter_id.to_s.to_sym]
        }
      end

      addItemsObj = JSON.generate(items)
      run_javascript("R8.Workspace.addItems(#{addItemsObj});")

      #---------------------------------------------

      return {
        :content => '',
        :panel => 'viewspace'
      }
    end

    def add_item(id)
#      id_handle = id_handle(id)
=begin
      hash = request.params.dup
      target_id_handle = nil
      if hash["target_id"] and hash["target_model_name"]
        input_target_id_handle = id_handle(hash["target_id"].to_i,hash["target_model_name"].to_sym)
        target_id_handle = Model.find_real_target_id_handle(id_handle,input_target_id_handle)
      elsif hash["target_uri"] and hash["obj"]#TODO: stub for testing
        c = ret_session_context_id()
        target_id_handle = IDHandle.new({:c => c, :uri => hash["target_uri"]},{:set_parent_model_name => true})
        target_id = target_id_handle.get_id()
      else
        Log.info("not implemented yet")
        return redirect "/xyz/#{model_name()}/display/#{id.to_s}"
      end
=end
      #TODO: need to copy in avatar when hash["ui"] is non null
      datacenter = id_handle(id,:datacenter).create_object()

#      override_attrs = request.params["ui"] ? {:ui=>request.params["ui"]} : {}

      model_id_handle = id_handle(request.params["id"].to_i,request.params["model"].to_sym)
      new_id = datacenter.add_item(request.params["id"],request.params["model"],request.params["ui"])
      id = new_id if new_id

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

    def get_links(id)
      datacenter = id_handle(id,:datacenter).create_object()
      item_list = JSON.parse(request.params["item_list"])

#TODO: move this call into underlying get_links call,
      item_list = item_list.map{|x|id_handle(x["id"].to_i,x["model"].to_sym)}
#TODO: make get_links an instance method, should pull all links from children if item_list is []/nil
      link_list = datacenter.class.get_links(item_list)
      return {'data'=>link_list}
    end

  end
end
