module XYZ
  class NodeController < Controller
    helper :i18n_string_mapping

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

    def get(id)
      node = create_object_from_id(id)
      return {:data=>node.get_obj_with_common_cols()}
    end

    ###TODO test
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
pp foo
pp '++++++++++++++++++++++++++++++'

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
      params = request.params.dup
      cols = model_class(:node).common_columns()

      filter_conjuncts = params.map do |name,value|
        [:regex,name.to_sym,"^#{value}"] if cols.include?(name.to_sym)
      end.compact

      #restrict results do not nested in assembly
      filter_conjuncts << [:eq,:assembly_id,nil]
      #including library forces join and filter on library; so makes sure only nodes from library returned and ones
      #that the user is authorized to see
      cols << :library unless cols.include?(:library)
      sp_hash = {
        :cols => cols,
        :filter => [:and] + filter_conjuncts
      }
      node_list = Model.get_objs(model_handle(:node),sp_hash).each{|r|r.materialize!(cols)}

      i18n = get_i18n_mappings_for_models(model_name)
      node_list.each_with_index do |model,index|
        node_list[index][:model_name] = model_name
        body_value = ''
        node_list[index][:ui] ||= {}
        node_list[index][:ui][:images] ||= {}
        name = node_list[index][:display_name]
        title = name.nil? ? "" : i18n_string(i18n,:node,name)

        #TDOO: temporary to distingusih between chef and puppet components
        if model_name == :node
          if config_agent_type = node_list[index][:config_agent_type]
            title += " (#{config_agent_type[0].chr})" 
          end
        end
        
#TODO: change after implementing all the new types and making generic icons for them
        model_type = 'service'
        model_sub_type = 'db'
        model_type_str = "#{model_type}-#{model_sub_type}"
        prefix = "#{R8::Config[:base_images_uri]}/v1/nodeIcons"
        png = node_list[index][:ui][:images][:tnail] || "unknown-#{model_type_str}.png"
        node_list[index][:image_path] = "#{prefix}/#{png}"

        node_list[index][:i18n] = title
      end

      return {:data=>node_list}
    end

  end
end

