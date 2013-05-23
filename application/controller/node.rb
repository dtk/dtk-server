module XYZ
  class NodeController < AuthController
    helper :node_helper
    helper :rest_async
    helper :component_template_helper

    ### mcollective actions
    def rest__initiate_get_netstats()
      node = create_node_obj(:node_id)
      queue = ActionResultsQueue.new
      # TODO: Move GetNetstas MColl action class to shared location between assembly and node controllers
      Assembly::Instance::Action::GetNetstats.initiate([node], queue) 
      rest_ok_response :action_results_id => queue.id
    end
    
    def rest__initiate_get_ps()
      node = create_node_obj(:node_id)
      queue = ActionResultsQueue.new
      
      Assembly::Instance::Action::GetPs.initiate([node], queue) 
      rest_ok_response :action_results_id => queue.id
    end

    def rest__get_action_results()
      #TODO: to be safe need to garbage collect on ActionResultsQueue in case miss anything
      action_results_id = ret_non_null_request_params(:action_results_id)
      ret_only_if_complete = ret_request_param_boolean(:return_only_if_complete)
      disable_post_processing = ret_request_param_boolean(:disable_post_processing)

      if ret_request_param_boolean(:using_simple_queue)
        rest_ok_response SimpleActionQueue.get_results(action_results_id)
      else
        rest_ok_response ActionResultsQueue.get_results(action_results_id,ret_only_if_complete,disable_post_processing)
      end
    end

    #### create and delete actions ###
    def rest__add_component()
      node = create_node_obj(:node_id)
      component_template_idh = ret_component_template_idh()
      new_component_idh = node.add_component(component_template_idh)
      rest_ok_response(:component_id => new_component_idh.get_id())
    end

    def rest__delete_component()
      node = create_node_obj(:node_id)
      #not checking here if component_id points to valid object; check is in delete_component
      component_id = ret_non_null_request_params(:component_id)
      node.delete_component(id_handle(component_id,:component))
      rest_ok_response
    end

    def rest__destroy_and_delete()
      node = create_node_obj(:node_id)
      node.destroy_and_delete()
      rest_ok_response
    end

    def rest__start()
      node     = create_node_obj(:node_id)
      nodes    = get_objects(:node, { :id => node[:id]})
      node_idh = ret_request_param_id_handle(:node_id)

      nodes, is_valid, error_msg = node_valid_for_aws?(nodes, :stopped)

      unless is_valid
        return rest_ok_response(:errors => [error_msg])
      end

      queue = SimpleActionQueue.new

      CreateThread.defer do
        # invoking command to start the nodes
        CommandAndControl.start_instances(nodes)

        task = Task.power_on_from_node(node_idh)
        task.save!()

        queue.set_result(:task_id => task.id)
      end

      rest_ok_response :action_results_id => queue.id
    end

    def rest__stop()
      node  = create_node_obj(:node_id)
      nodes = get_objects(:node, { :id => node[:id]})

      nodes, is_valid, error_msg = node_valid_for_aws?(nodes, :running)

      unless is_valid
       return rest_ok_response(:errors => [error_msg])
      end
      
      CommandAndControl.stop_instances(nodes)
      rest_ok_response :status => :ok
    end

    def node_valid_for_aws?(nodes, status_pattern)
      # check if staged
      if nodes.first[:type] == "staged"
        return nodes, false, "Node with id '#{nodes.first[:id]}' is 'staged' and as such cannot be started/stopped."
      end

      # check for status -> this will translate to /running|pending/ and /stopped|pending/ checks
      node = nodes.first[:admin_op_status] =~ Regexp.new("#{status_pattern.to_s}|pending")
      if node.nil?
        return nodes, false, "There are no #{status_pattern} nodes with id '#{nodes.first[:id]}'"
      end
      
      return nodes, true, nil      
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__list()
      target_name, is_list_all = ret_request_params(:target_indentifier, :is_list_all)
      target_id = DTK::Datacenter.name_to_id(model_handle(:datacenter), target_name) if target_name && !target_name.empty?
      response = ret_nodes_by_subtype_class(model_handle(), { :target_id => target_id, :is_list_all => is_list_all })
      rest_ok_response response
    end

    def rest__info()
      node,subtype = ret_node_params_object_and_subtype()
       unless subtype == :instance
         raise ErrorUsage::BadParamValue.new(:subtype,subtype)
       end
      rest_ok_response node.info()
    end

    def rest__info_about()
      node,subtype = ret_node_params_object_and_subtype()
      about = ret_non_null_request_params(:about).to_sym
       unless AboutEnum[subtype].include?(about)
         raise ErrorUsage::BadParamValue.new(:about,AboutEnum[subtype])
       end
      rest_ok_response node.info_about(about)
    end
    AboutEnum = {
      :instance => [:components,:attributes],
#      :template => [:nodes,:components,:targets]
    }

    def rest__get_attributes()
      node = create_node_obj(:node_id)
      filter = ret_request_params(:filter)
      filter = filter && filter.to_sym
      rest_ok_response node.get_attributes_print_form(filter)
    end

    #the body has an array each element of form
    # {:pattern => PAT, :value => VAL}
    #pat can be one of three forms
    #1 - an id
    #2 - a name of form ASSEM-LEVEL-ATTR or NODE/COMONENT/CMP-ATTR, or 
    #3 - a pattern (TODO: give syntax) that can pick out multiple vars
    # this returns same output as info about attributes, pruned for just new ones set
    def rest__set_attributes()
      node = create_node_obj(:node_id)
      av_pairs = ret_params_av_pairs()
      response = node.set_attributes(av_pairs)
      if response.empty?
        raise ErrorUsage.new("No attributes match")
      end
      rest_ok_response response
    end

    #### end: list and info actions ###

    #### creates tasks to execute/converge assemblies and monitor status
    def rest__stage()
      target = create_target_obj_with_default(:target_id)
      #TODO: would like to use form, but need to fix these fns up to do so: node_binding_rs =  create_obj(:node_template_id,NodeBindingRuleset)
      node_binding_identifier = ret_request_params(:node_template_identifier)
      node_binding_rs_id = NodeBindingRuleset.name_to_id(model_handle(:node_binding_ruleset),node_binding_identifier)
      node_binding_rs = create_object_from_id(node_binding_rs_id,:node_binding_ruleset)

      opts = Hash.new
      if node_name = ret_request_params(:name)
        opts[:override_attrs] = {:display_name => node_name}
      end
      node_instance_idh = node_binding_rs.clone_or_match(target,opts)
      rest_ok_response :node_id => node_instance_idh.get_id()
    end

    def rest__create_task()
      node_idh = ret_request_param_id_handle(:node_id)
      commit_msg = ret_request_params(:commit_msg)
      unless task = Task.create_from_node(node_idh,commit_msg)
        raise ErrorUsage.new("No changes to converge")
      end
      task.save!()
      rest_ok_response :task_id => task.id
    end

    def rest__task_status()
      node_idh = ret_request_param_id_handle(:node_id)
      format = (ret_request_params(:format)||:hash).to_sym
      rest_ok_response Task::Status::Node.get_status(node_idh,:format => format)
    end
    #### end: creates tasks to execute/converge assemblies and monitor status

    def rest__image_upgrade()
      old_image_id,new_image_id = ret_non_null_request_params(:old_image_id,:new_image_id)
      Node::Template.image_upgrade(model_handle(),old_image_id,new_image_id)
      rest_ok_response 
    end

    def rest__get_op_status()
      node = create_node_obj(:node_id)
      rest_deferred_response do |handle|
        status = node.get_and_update_status!()
        handle.rest_ok_response(:op_status => status)
      end
    end

##### TODO: below needs cleanup

    def rest__add_to_group()
      node_id, node_group_id = ret_non_null_request_params(:node_id, :node_group_id)
      node_group = create_object_from_id(node_group_id,:node_group)
      unless parent_id = node_group.update_object!(:datacenter_datacenter_id)[:datacenter_datacenter_id]
        raise Error.new("node group with id (#{node_group_id.to_s}) given is not in a target")
      end
      node = create_object_from_id(node_id)
      node_group.add_member(node,id_handle(parent_id,:target))
      rest_ok_response
    end


    helper :i18n_string_mapping

    def get(id)
      node = create_object_from_id(id)
      return {:data=>node.get_obj_with_common_cols()}
    end

    #TODO: this should be a post; so transitioning over
    def destroy_and_delete(id=nil)
      id ||= request.params["id"]
      create_object_from_id(id).destroy_and_delete()
      return {:data => {:id=>id,:result=>true}}
    end
    ######

    def actest
      tpl = R8Tpl::TemplateR8.new("node/actest",user_context())
      tpl.assign(:_app,app_common())
      foo = tpl.render()

      return {
        :content => foo
      }
    end
    def overlaytest
      tpl = R8Tpl::TemplateR8.new("node/overlaytest",user_context())
      tpl.assign(:_app,app_common())
      foo = tpl.render()

      return {
        :content => foo
      }
    end

    def dock_get_service_checks(id)
      node = create_object_from_id(id)
      node_service_checks = node.get_node_service_checks()
      component_service_checks = node.get_component_service_checks()
      pp [:node_service_checks,node_service_checks]
      pp [:component_service_checks,component_service_checks]
      tpl = R8Tpl::TemplateR8.new("dock/node_get_service_checks",user_context())
      tpl.assign(:_app,app_common())
      tpl.assign(:node_service_checks,node_service_checks)
      tpl.assign(:component_service_checks,component_service_checks)

      panel_id = request.params['panel_id']

      return {
        :content => tpl.render(),
        :panel => panel_id
      }
    end

    def dock_get_users(id)
      node = create_object_from_id(id)
      user_list = node.get_users()

      tpl = R8Tpl::TemplateR8.new("dock/node_get_users",user_context())
      tpl.assign(:_app,app_common())
      tpl.assign(:user_list,user_list)

      panel_id = request.params['panel_id']

      return {
        :content => tpl.render(),
        :panel => panel_id
      }
    end

    def dock_get_applications(id)
      node = create_object_from_id(id)
      app_list = node.get_applications()

      tpl = R8Tpl::TemplateR8.new("dock/node_get_apps",user_context())
      tpl.assign(:_app,app_common())
      tpl.assign(:app_list,app_list)

      panel_id = request.params['panel_id']

      return {
        :content => tpl.render(),
        :panel => panel_id
      }
    end

    def get_ports(id)
      node = create_object_from_id(id)
      port_list = node.get_ports("component_external","component_internal_external")
      return {:data=>port_list}
    end

    def ac_remotesearch
pp '++++++++++++++++++++++++++++++'
pp request.params
      results_array = Array.new
      results_array << 'Michael Jordan'
      results_array << 'Scotty Pippen'
      results_array << 'Magic Johnson'
      results_array << 'Larry Bird'
      results_array << 'David Robinson'
      results_array << 'LeBron James'
      results_array << 'Al Harrington'
      results_array << 'Baron Davis'
      results_array << 'Charles Barkely'
      results_array << 'Chuck Johnson'
      results_array << 'Cal Hooper'
      results_array << 'Dominique Wilkins'
pp results_array

      return {
        :data => results_array
      }
    end

    def wspace_display(id)
      c = ret_session_context_id()
      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())

      tpl.set_js_tpl_name('node_wspace_display')
#      node = get_object_by_id(id)
 #     node.delete(:image_size)
      node = Node.get_wspace_display(IDHandle[:c => c, :guid => id])

#TODO: temp hack to stub things out
node[:operational_status] = 'good'
node[:model_name] = 'node'

      tpl.assign(:node,node)
      tpl.assign(:base_images_uri,R8::Config[:base_images_uri])

      num_components = (node[:component]||[]).map{|x|x[:id]}.uniq.size
      tpl.assign(:num_components,num_components)

      _node_vars = {}
      _node_vars[:i18n] = get_model_i18n("node",user_context())
      tpl.assign("_node",_node_vars)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'viewspace'
      tpl_result[:assign_type] = 'append'

      return tpl_result
    end

    def wspace_display_2(id)
#TODO: decide if toolbar is needed/used at node level
      #need to augment for nodes that are in datacenter directly and not node groups
      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())
      tpl.set_js_tpl_name("node_wspace_display")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      field_set = Model::FieldSet.default(:node)
      node = get_object_by_id(id,:node)
#pp node_list
      items = Array.new
      item = {
          :type => 'node',
          :object => node,
          :toolbar_def => {},
          :tpl_callback => tpl_info[:template_callback],
          :ui => node[:ui]
      }
#DEBUG
=begin
        item = {
          :type => model_name.to_s,
          :object => node,
          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info[:template_callback],
          :ui => node[:ui][datacenter_id.to_sym]
        }
=end
      items << item

      addItemsObj = JSON.generate(items)
      run_javascript("R8.Workspace.addItems(#{addItemsObj});")

      #---------------------------------------------

      return {}
    end

    def wspace_display_ide(id)
#TODO: decide if toolbar is needed/used at node level
      #need to augment for nodes that are in datacenter directly and not node groups
      tpl = R8Tpl::TemplateR8.new("node/wspace_display_ide",user_context())
      tpl.set_js_tpl_name("node_wspace_display_ide")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      field_set = Model::FieldSet.default(:node)
      node = get_object_by_id(id,:node)
#pp node_list
      items = Array.new
      item = {
          :type => 'node',
          :object => node,
          :toolbar_def => {},
          :tpl_callback => tpl_info[:template_callback],
          :ui => node[:ui]
      }
#DEBUG
=begin
        item = {
          :type => model_name.to_s,
          :object => node,
          :toolbar_def => toolbar_def,
          :tpl_callback => tpl_info[:template_callback],
          :ui => node[:ui][datacenter_id.to_sym]
        }
=end
      items << item

#      addItemsObj = JSON.generate(items)
#      run_javascript("R8.Workspace.addItems(#{addItemsObj});")

      #---------------------------------------------

      return {:data=>items}
    end

    def added_component_conf(id)
      node = get_object_by_id(id)
      display_name = node[:display_name]
      alert_str = 'Added Component to Node('+display_name+')'
      run_javascript("R8.Workspace.showAlert('#{alert_str}');")

      return {}
    end

    def added_component_conf_ide(id)
      node = get_object_by_id(id)
      display_name = node[:display_name]
      alert_str = 'Added Component to Node('+display_name+')'
#      run_javascript("R8.Workspace.showAlert('#{alert_str}');")

      return {:data=>alert_str}
    end

    def wspace_refresh(id)
      c = ret_session_context_id()
      tpl = R8Tpl::TemplateR8.new("node/wspace_refresh",user_context())

      tpl.set_js_tpl_name('node_wspace_refresh')
#      node = get_object_by_id(id)
 #     node.delete(:image_size)
      node = Node.get_wspace_display(IDHandle[:c => c, :guid => id])

#TODO: temp hack to stub things out
node[:operational_status] = 'good'
node[:model_name] = 'node'

      tpl.assign(:node,node)
      tpl.assign(:base_images_uri,R8::Config[:base_images_uri])

      num_components = (node[:component]||[]).map{|x|x[:id]}.uniq.size
      tpl.assign(:num_components,num_components)

      _node_vars = {}
      _node_vars[:i18n] = get_model_i18n("node",user_context())
      tpl.assign("_node",_node_vars)

      tpl_result = tpl.render()
      tpl_result[:panel] = 'item-'+node[:id].to_s
#      tpl_result[:assign_type] = 'append'
p 'Panel IS:'+tpl_result[:panel]

      return tpl_result
    end

    def get_components(id)
      model_name = :component
      field_set = Model::FieldSet.default(model_name)
      component_list = get_objects(model_name,{:node_node_id=>id})

=begin
Expect something like:
node = Node.new(node_id)
component_list = node.get_components()

get_components should probably take a param to return sub list of type(s) of components
ie: get_components(['language'])
=end
#pp model_list
      component_i18n = get_model_i18n('component',user_context())

      component_list.each do |component|
        pp '--------------------'
        pp 'component:'+component[:display_name]
        pp 'id:'+component[:id].to_s
        component_name = component[:display_name].gsub('::','_')

        component[:label] = component_i18n[(component[:ds_attributes]||{})[:ref].to_sym]  if (component[:ds_attributes]||{})[:ref]  
        component[:label] ||= component_i18n[component_name.to_sym] || "component"
                             
        component[:onclick] = "R8.Workspace.Dock.loadDockPanel('component/wspace_dock_get_attributes/#{component[:id].to_s}');"
#        component[:onclick] = "R8.Workspace.Dock.loadDockPanel('node/get_components/2147484111');"
      end

      return {} if component_list.empty?
      component_list[0][:css_class] = 'first'
      component_list[component_list.length-1][:css_class] = 'last'

      tpl = R8Tpl::TemplateR8.new("workspace/dock_list",user_context())
#      tpl.assign(:component_list,component_list)
      js_tpl_name = 'wspace_dock_list'
      tpl.set_js_tpl_name(js_tpl_name)
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      panel_id = request.params['panel_id']

      panel_cfg_hash = {
        :title=>{
          :i18n=>component_i18n[:components]
        },
        :item_list=>component_list,
      }
      panel_cfg = JSON.generate(panel_cfg_hash)
#TODO: temp pass of
      run_javascript("R8.Workspace.Dock.pushDockPanel2('0',#{panel_cfg},'#{js_tpl_name}');")

      return {}

=begin
      return {:data=>{
          :panel_cfg=>panel_cfg
        }
      }
      return {
#        :content=>tpl.render(),
        :data=> {
          :component_list => component_list
        },
        :panel=>panel_id
      }
=end
    end

    def wspace_render_ports(id=nil)
      filter = [:and,[:eq,:is_port,true],[:eq,:port_is_external,true]]
      cols = [:id,:display_name,:value_derived,:value_asserted]
      field_set = Model::FieldSet.new(:attribute,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => id.to_i) if id
      port_list = ds.all
      port_list.each do |el|
        val = el[:attribute_value]
        el[:value] = (val.kind_of?(Hash) or val.kind_of?(Array)) ? JSON.generate(val) : val
      end

#      action_name = "list_ports_under_node"
#      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
#      tpl.assign("port_list",port_list)
#      return {:content => tpl.render()}

      ports = JSON.generate(port_list)
      run_javascript("R8.Workspace.renderItemPorts('#{id}',#{ports});")

      return {}
    end

    def search
      #TODO: harmonize with rest__list
      search_cols = [:display_name]

      filter_conjuncts = request.params.map do |name,value|
        [:regex,name.to_sym,"^#{value}"] if search_cols.include?(name.to_sym)
      end.compact
      cols = NodeBindingRuleset.common_columns()
      sp_hash = {
        :cols => cols + [:ref]
      }

      unless filter_conjuncts.empty?
        sp_hash[:filter] = [:and] + filter_conjuncts
      end
      node_list = Model.get_objs(model_handle(:node_binding_ruleset),sp_hash,:keep_ref_cols => true).each{|r|r.materialize!(cols)}
      icon_dir = "#{R8::Config[:base_images_uri]}/v1/nodeIcons"
      node_list.each do |node|
        png = (node[:os_type] ? "#{node[:os_type]}.png" : "unknown-node.png")
        node[:image_path] = "#{icon_dir}/#{png}"
        node[:display_name] ||= node[ref]
        node[:i18n] = node[:display_name]
      end
      {:data=>node_list}
    end
  end
end

