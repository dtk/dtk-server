module XYZ
  class NodeController < Controller
    helper :i18n_string_mapping
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

    def dock_get_users(id)
      search_pattern_hash = {
        :relation => :node,
        :filter => [:and,[:eq, :id, id.to_i]],
        :columns => [:users]
      }
      node_user_list = get_objects_from_search_pattern_hash(search_pattern_hash)

      #TODO: test in case null
      user_list = [
        {:id=>'1231231',:username=>'bob',:avatar_filename => 'generic-user-male.png'},
        {:id=>'1231231',:username=>'jim',:avatar_filename => 'generic-user-male.png'},
        {:id=>'1231231',:username=>'greg',:avatar_filename => 'generic-user-male.png'},
        {:id=>'1231231',:username=>'sally',:avatar_filename => 'generic-user-male.png'}
      ]
      #TODO: just putting in username, not uid or gid
      unless node_user_list.empty?
        user_list = node_user_list.map do |u|
          attr = u[:attribute]
          val = attr[:value_asserted]||attr[:value_derived]
          (val and attr[:display_name] == "username") ? {:id => attr[:id], :username => val, :avatar_filename => 'generic-user-male.png'} : nil 
        end.compact
      end

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
      search_pattern_hash = {
        :relation => :node,
        :filter => [:and,[:eq, :id, id.to_i]],
        :columns => [:applications]
      }
      node_app_list = get_objects_from_search_pattern_hash(search_pattern_hash)
pp '*************************************'
      app_list = [
        {:id=>'1231231',:name=>'postgres'},
        {:id=>'1231231',:name=>'hive'},
        {:id=>'1231231',:name=>'cloudera'},
        {:id=>'1231231',:name=>'foo'}
      ]

      #computing teh components
      unless node_app_list.empty?
        indexed_app_list = Hash.new()
        node_app_list.each do |r|
          next unless r[:component]
          id = r[:component][:id]
          #TODO: ?: run display name through i18n mappings
          unless indexed_app_list[id]
            el = {:id => id, :name =>  r[:component][:display_name]} 
            component_icon_filename = ((r[:component][:ui]||{})[:images]||{})[:tnail]
            el.merge!(:component_icon_filename => component_icon_filename) if component_icon_filename
            indexed_app_list[id] = el
          end
        end
        app_list =  indexed_app_list.values
pp [:app_list,app_list]
      end
      #computing attributes
      #TODO: should have get_objects_from_search_pattern_hash convert Hash to Attribute
      raw_attributes = node_app_list.map{|r|r[:attribute] && Attribute.new(r[:attribute],ret_session_context_id(),:attribute)}.compact
      cmp_parent = DB.parent_field(:component,:attribute)
      attr_cols = [:id,{:display_name => :name},:cannot_change,:required,:dynamic,:data_type,{:attribute_value => :value},{cmp_parent => :component_id}]
      attribute_list = AttributeComplexType.flatten_attribute_list(raw_attributes).map{|h|Aux.hash_subset(h,attr_cols)}
      ## put in ii18n strings
      i18n = get_i18n_mappings_for_model(:attribute)
      attribute_list.each do |a|
        a[:i18n] = i18n_string_attribute(i18n,a[:name].to_sym) 
      end
      pp [:attribute_list,attribute_list]

      tpl = R8Tpl::TemplateR8.new("dock/node_get_apps",user_context())
      tpl.assign(:_app,app_common())
      tpl.assign(:app_list,app_list)

      panel_id = request.params['panel_id']

      return {
        :content => tpl.render(),
        :panel => panel_id
      }
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
pp '{{{{{{{{{{{{{{{{{{{{{{{{{['
pp items
      addItemsObj = JSON.generate(items)
      run_javascript("R8.Workspace.addItems(#{addItemsObj});")

      #---------------------------------------------

      return {}
    end

    def added_component_conf(id)
      node = get_object_by_id(id)
      display_name = node[:display_name]
      alert_str = 'Added Component to Node('+display_name+')'
      run_javascript("R8.Workspace.showAlert('#{alert_str}');")

      return {}
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
      cols = [:id,:display_name,:base_object_node,:value_derived,:value_asserted]
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

    def get_ports(id=nil)
      filter = [:and,[:eq,:is_port,true],[:eq,:port_is_external,true]]
      cols = [:id,:display_name,:base_object_node,:value_derived,:value_asserted,:port_type,:description]
      field_set = Model::FieldSet.new(:attribute,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_node_id => id.to_i) if id
      port_list = ds.all
      port_list.each do |el|
        val = el[:attribute_value]
        el[:value] = (val.kind_of?(Hash) or val.kind_of?(Array)) ? JSON.generate(val) : val
        #TODO: probably shoudl isntead use virtual column that provides qualified name
        if el[:display_name] and (el[:component]||{})[:display_name]
          el[:display_name] = "#{el[:component][:display_name].gsub("::","/")}/#{el[:display_name]}"
        end
      end

      Model::materialize_virtual_columns!(port_list,[:port_type])
      return {:data=>port_list}
    end

  end
end

