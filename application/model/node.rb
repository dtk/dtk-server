module XYZ
  class Node < Model
#    extend ClassMixinDataSourceExtensions
    set_relation_name(:node,:node)
#TODO: move this out into central model, should read off of model meta data for processing
    def self.up()
      ds_column_defs :ds_attributes, :ds_key, :data_source, :ds_source_obj_type
      external_ref_column_defs()
      virtual_column :name, :type => :varchar, :local_dependencies => [:display_name]
      column :tag, :varchar
      #TODO: may change types; by virtue of being in alibrary we know about item; may need to distingusih between backed images versus barbones one; also may only treat node constraints with search objects
      column :type, :varchar, :size => 25, :default => "instance" # | "image" #TODO: any more states possible
      column :os_type, :varchar, :size => 25
      column :architecture, :varchar, :size => 10 #e.g., 'i386'
      #TBD: in data source specfic now column :manifest, :varchar #e.g.,rnp-chef-server-0816-ubuntu-910-x86_32
      #TBD: experimenting whetehr better to make this actual or virtual columns
      column :image_size, :numeric, :size=>[8, 3] #in megs

      #TODO: may replace is_deployed and operational_status with status
      column :is_deployed, :boolean, :default => false
      column :operational_status, :varchar, :size => 50
      virtual_column :status, :type => :varchar, :local_dependencies => [:is_deployed,:operational_status]
      column :ui, :json
      foreign_key :assembly_id, :component, FK_SET_NULL_OPT
      virtual_column :target_id, :type => ID_TYPES[:id], :local_dependencies => [:datacenter_datacenter_id]
      virtual_column :parent_name, :possible_parents => [:library,:datacenter]
      virtual_column :disk_size, :path => [:ds_attributes,:flavor,:disk] #in megs
      #TODO how to have this conditionally "show up"
      virtual_column :ec2_security_groups, :path => [:ds_attributes,:groups] 

      virtual_column :project, :type => :json, :hidden => true,
        :remote_dependencies =>
        [{
           :model_name => :datacenter,
           :join_type => :inner,
           :join_cond => {:id => p(:node,:datacenter)},
           :cols => [:id,:project_id]
         },
         {
           :model_name => :project,
           :convert => true,
           :join_type => :inner,
           :join_cond => {:id => q(:datacenter,:project_id)},
           :cols => [:id,:display_name,:type]
         }]

      ##### for connection to ports and port links
      virtual_column :node_link_defs_info, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :component,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name,:component_type, :extended_base, :implementation_id, :node_node_id]
         },
         {
           :model_name => :link_def,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:component_component_id => q(:component,:id)},
           :cols => [:id,id(:component),:local_or_remote,:link_type,:has_external_link,:has_internal_link]
         },
         {
           :model_name => :port,
           :convert => true,
           :join_type => :left_outer,
           :join_cond=>{:link_def_id => q(:link_def,:id)},
           :cols => [:id,:display_name,:type,:connected]
         }]

      virtual_column :ports, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :port,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:type,id(:node),:containing_port_id,:external_attribute_id,:direction,:location,:ref,:display_name,:name,:description] #TODO: should we unify with Port.common_columns
         }]

      virtual_column :output_attrs_to_l4_input_ports, :type => :json, :hidden => true,
        :remote_dependencies =>
        [
         {
           :model_name => :port,
           :alias => :port_external_output,
           :join_type => :inner,
           :filter => [:eq,:type,"external"],
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,id(:node),:containing_port_id,:external_attribute_id]
         },
         {
           :model_name => :port_link,
           :alias => :port_link_l4,
           :join_type => :inner,
           :join_cond=>{:output_id => q(:port_external_output,:containing_port_id)},
           :cols => [:input_id]
         },
         { :model_name => :port,
           :alias => :port_l4_input,
           :join_type => :inner,
           :filter => [:eq,:type,"l4"],
           :join_cond=>{:id => q(:port_link_l4,:input_id)},
           :cols => [:id,id(:node)]
         }]

      input_port_links_def = 
        [{
           :model_name => :port,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name,:type]
         },
        {
           :model_name => :port_link,
           :convert => true,
           :join_cond=>{:input_id =>q(:port,:id)},
           :join_type => :inner,
           :cols => [:id,:input_id,:output_id]
         }]
      virtual_column :input_port_links, :type => :json, :hidden => true, 
      :remote_dependencies => input_port_links_def 

      virtual_column :input_port_link_info, :type => :json, :hidden => true, 
      :remote_dependencies => 
        input_port_links_def +
        [{
           :model_name => :port,
           :alias => :attr_other_end,
           :join_cond=>{:id =>q(:port_link,:output_id)},
           :join_type => :inner,
           :cols => [:id,:display_name,:type]
         }]

      output_port_links_def =
        [{
           :model_name => :port,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name,:type]
         },
        {
           :model_name => :port_link,
           :convert => true,
           :join_cond=>{:output_id =>q(:port,:id)},
           :join_type => :inner,
           :cols => [:id,:input_id,:output_id]
         }]

      virtual_column :output_port_links, :type => :json, :hidden => true, 
      :remote_dependencies => output_port_links_def
      virtual_column :output_port_links, :type => :json, :hidden => true, 
      :remote_dependencies => 
        output_port_links_def +
         [{
           :model_name => :port,
           :alias => :attr_other_end,
           :join_cond=>{:id =>q(:port_link,:input_id)},
           :join_type => :inner,
           :cols => [:id,:display_name,:type]
         }]


      cmp_attrs_on_node_def = 
        [{
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name, :component_type, id(:node)]
         },
         {
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=>{:component_component_id => q(:component,:id)},
           :cols => [:id,:display_name]
         }]
      virtual_column :input_attribute_links, :type => :json, :hidden => true, 
      :remote_dependencies => 
        cmp_attrs_on_node_def +
        [
         {
           :model_name => :attribute_link,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:input_id => q(:attribute,:id)},
           :cols => [:id,:display_name, :type, :input_id,:output_id]
         }]
      virtual_column :output_attribute_links, :type => :json, :hidden => true, 
      :remote_dependencies => 
        cmp_attrs_on_node_def +
        [
         {
           :model_name => :attribute_link,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:output_id => q(:attribute,:id)},
           :cols => [:id,:display_name, :type, :input_id,:output_id]
         }]

      #used when node is deleted to find and update dangling attribute linkss
      virtual_column :dangling_input_links_from_components, :type => :json, :hidden => true, 
      :remote_dependencies => 
        cmp_attrs_on_node_def +
        [
         {
           :model_name => :attribute_link,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:output_id => q(:attribute,:id)},
           :cols => [:id, :type, :input_id,:index_map]
         },
         {
           :model_name => :attribute_link,
           :alias => :all_input_links,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:input_id => q(:attribute_link,:input_id)},
           :cols => [:id,:type, :input_id,:index_map]
         }]

      virtual_column :dangling_input_links_from_nodes, :type => :json, :hidden => true, 
      :remote_dependencies => 
         [{
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name]
          },
         {
           :model_name => :attribute_link,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:output_id => q(:attribute,:id)},
           :cols => [:id, :type, :input_id,:index_map]
         },
         {
           :model_name => :attribute_link,
           :alias => :all_input_links,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:input_id => q(:attribute_link,:input_id)},
           :cols => [:id,:type, :input_id,:index_map]
         }]


      ##### end of for connection to ports and port links

      virtual_column :components, :type => :json, :hidden => true,
      :remote_dependencies =>
        [
         {
           :model_name => :component,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:node_node_id =>:node__id},
           :cols => [:id,:display_name]
         }]

        virtual_column :has_pending_change, :type => :boolean, :hidden => true,
         :remote_dependencies =>
         [
          {
            :model_name => :action,
            #TODO: avoidng use of :node__node
            :sequel_def => lambda{|ds|ds.where(:state => "pending").join(:component__component,{:id => :component_id}).group_and_count(:component__node_node_id)},
            :join_type => :left_outer,
            :join_cond=>{:node_node_id =>:node__id}
          }]


      virtual_column :violations, :type => :json, :hidden => true,
      :remote_dependencies => 
        [
         {
           :model_name => :violation,
           :join_type => :inner,
           :convert => true,
           :join_cond=>{:target_node_id => q(:node,:id)},
           :cols=>[:id,:display_name,:severity,:description,:expression,:target_node_id,:updated_at]
         }]

      virtual_column :users, :type => :json, :hidden => true,
      :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :filter => [:and, [:eq, :basic_type, "user"]],
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols=>[:id,:node_node_id]
         },
         {
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=>{:component_component_id => q(:component,:id)},
           :cols=>[:id,:component_component_id,:display_name,:value_asserted,:value_derived]
         }
        ]


      monitoring_items_cols_def = [:id,:display_name,:service_name,:condition_name,:condition_description,:enabled,:params,:attributes_to_monitor]
      virtual_column :monitoring_items__node, :type => :json, :hidden => true,
      :remote_dependencies =>
        [
         {
           :model_name => :monitoring_item,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols=> monitoring_items_cols_def
         },
        ]
      virtual_column :monitoring_items__component, :type => :json, :hidden => true,
      :remote_dependencies =>
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols=>[:id,:display_name]
         },
         {
           :model_name => :monitoring_item,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:component_component_id => q(:component,:id)},
           :cols=>monitoring_items_cols_def
         },
        ]

      #TODO: just for testing
      application_basic_types = %w{application service database language extension}
      #in dock 'applications means wider than basic_type == applicationsn
      virtual_column :applications, :type => :json, :hidden => true,
      :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :filter => [:and,[:oneof, :basic_type, application_basic_types]],
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols=>[:id,:node_node_id,:display_name,:ui]
         }
        ]
      virtual_column :monitoring_agents, :type => :json, :hidden => true,
      :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :filter => [:eq, :specific_type, "monitoring_agent"],
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols=>[:id,:node_node_id,:display_name]
         }
        ]

      virtual_column :deprecate_port_links, :type => :json, :hidden => true, 
      :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:node_node_id =>:node__id},
           :cols => [:id,:display_name,:node_node_id]
         },
         {
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=>{:component_component_id =>:component__id},
           :cols => [:id,:display_name,:component_component_id]
         },
         {
           :model_name => :attribute_link,
           :join_cond=>{:input_id =>:attribute__id},
           :cols => [:id,:type,:hidden,{:output_id => :other_end_output_id},:input_id,:node_node_id]
         },
         {
           :model_name => :attribute_link,
           :join_cond=>{:output_id =>:attribute__id},
           :cols => [:id,:type,:hidden,{:input_id => :other_end_input_id},:output_id,:node_node_id]
         }
        ]

      foreign_key :data_source_id, :data_source, FK_SET_NULL_OPT
      many_to_one :library, :datacenter
      one_to_many :attribute, :port, :attribute_link, :component, :node_interface, :address_access_point, :monitoring_item
    end

    def self.common_columns()
      [
       :id,
       :display_name,
       :name,
       :os_type,
       :type,
       :description,
       :status,
       :target_id,
       :ui
      ]
    end

    ### virtual column defs
    #######################
    #TODO: write as sql fn for efficiency
    def has_pending_change()
      ((self[:action]||{})[:count]||0) > 0
    end

    def status()
      (not self[:is_deployed]) ? "staged" : self[:operational_status]
    end

    def target_id()
      self[:datacenter_datacenter_id]
    end

    def name()
      self[:display_name]
    end

    #######################
    ######### Model apis
    def get_and_update_status!()
      #shortcut
      if has_key?(:is_deployed)
        return  "staged" if not self[:is_deployed]
      end
      update_object!(:is_deployed,:external_ref,:operational_status)
      return  "staged" if not self[:is_deployed]
      get_and_update_operational_status!()
    end

    def get_and_update_operational_status!()
      update_object!(:external_ref,:operational_status)
      op_status = CommandAndControl.get_node_operational_status(self)
      if op_status
        unless self[:operational_status] == op_status
          update_operational_status!(op_status)
        end
      end
      op_status || self[:operational_status]
    end

    #attribute on node
    def update_operational_status!(op_status)
      update(:operational_status => op_status.to_s)
      self[:operational_status] = op_status.to_s
    end

    def self.pbuilderid(node)
      (node[:external_ref]||{})[:instance_id]
    end
    def pbuilderid()
      Node.pbuilderid(self)
    end
    
    def get_virtual_attribute(attribute_name,cols,field_to_match=:display_name)
      sp_hash = {
        :model_name => :attribute,
        :filter => [:eq, field_to_match, attribute_name],
        :cols => cols
      }
      get_children_from_sp_hash(:attribute,sp_hash).first
    end
    #TODO: may write above in terms of below
    def get_virtual_attributes(attribute_names,cols,field_to_match=:display_name)
      sp_hash = {
        :model_name => :attribute,
        :filter => [:oneof, field_to_match, attribute_names],
        :cols => Aux.array_add?(cols,field_to_match)
      }
      get_children_from_sp_hash(:attribute,sp_hash)
    end

    def self.get_virtual_attributes(attrs_to_get,cols,field_to_match=:display_name)
      ret = Hash.new
      #TODO: may be able to avoid this loop
      attrs_to_get.each do |node_id,hash_value|
        attr_info = hash_value[:attribute_info]
        node = hash_value[:node]
        attr_names = attr_info.map{|a|a[:attribute_name].to_s}
        rows = node.get_virtual_attributes(attr_names,cols,field_to_match)
        rows.each do |attr|
          attr_name = attr[field_to_match]
          ret[node_id] ||= Hash.new
          ret[node_id][attr_name] = attr
        end
      end
      ret
    end

    #attribute on component on node
    #assumption is that component cannot appear more than once on node
    def get_virtual_component_attribute(cmp_assign,attr_assign,cols)
      base_sp_hash = {
        :model_name => :component,
        :filter => [:and, [:eq, cmp_assign.keys.first,cmp_assign.values.first],[:eq, :node_node_id,self[:id]]],
        :cols => [:id]
        }
      join_array = 
        [{
           :model_name => :attribute,
           :convert => true,
           :join_type => :inner,
           :filter => [:eq, attr_assign.keys.first,attr_assign.values.first],
           :join_cond => {:component_component_id => :component__id},
           :cols => cols.include?(:component_component_id) ? cols : cols + [:component_component_id]
         }]
      row = Model.get_objects_from_join_array(model_handle.createMH(:component),base_sp_hash,join_array).first
      row && row[:attribute]
    end

    def destroy_and_delete()
      update_object!(:external_ref)
      suceeeded = CommandAndControl.destroy_node?(self)
      if suceeeded
        update_dangling_links()
        Model.delete_instance(id_handle())
      end
    end

    def update_dangling_links()
      dangling_links_info_cmps = get_objs(:cols => [:dangling_input_links_from_components])
      dangling_links_info_nodes = get_objs(:cols => [:dangling_input_links_from_nodes])

      #TODO: if only processing external links, more efficeint to filter in sql query
      ndx_dangling_links_info = Hash.new
      (dangling_links_info_cmps + dangling_links_info_nodes).each do |r|
        link = r[:all_input_links]
        if link[:type] == "external"
          attr_id = link[:input_id]
          p = ndx_dangling_links_info[attr_id] ||= {:attribute_id => attr_id, :other_links => Array.new}
          new_el = {
            :attribute_link_id => link[:id], 
            :index_map => link[:index_map], 
          }
          if link[:id] == r[:attribute_link][:id]
            p[:deleted_link] = new_el
          else
            p[:other_links] << new_el
          end
        end
      end
      #TODO: need to get updated attributes to put on change list
      AttributeUpdateDerivedValues.update_for_delete_links(model_handle(:attribute),ndx_dangling_links_info.values)
    end
    private :update_dangling_links

    def get_project()
      get_objects_col_from_sp_hash(:cols => [:project]).first
    end

    def self.get_ports(id_handles)
      get_objs_in_set(id_handles,{:cols => [:ports]},{:keep_ref_cols => true}).map{|r|r[:port]}
    end

    def get_ports(*types)
      port_list = self.class.get_ports([id_handle])
      i18n = get_i18n_mappings_for_models(:component,:attribute)
      port_list.map{|port|port.filter_and_process!(i18n,*types)}.compact
    end

    def self.get_port_links(id_handles,*port_types)
      input_port_rows =  get_objs_in_set(id_handles,:columns => [:id, :display_name, :input_port_link_info]).select do |r|
        port_types.include?((r[:port]||{})[:type])
      end
      #TODO: implement using PortLink.common_columns and materialize
      input_port_rows.each do |r|
        r[:port_link][:ui] ||= {
          :type => R8::Config[:links][:default_type],
          :style => R8::Config[:links][:default_style]
        }
      end
      
      output_port_rows =  get_objs_in_set(id_handles,:columns => [:id, :display_name, :output_port_link_info]).select do |r|
        port_types.include?((r[:port]||{})[:type])
      end
      #TODO: implement using PortLink.common_columns and materialize
      output_port_rows.each do |r|
        r[:port_link][:ui] ||= {
          :type => R8::Config[:links][:default_type],
          :style => R8::Config[:links][:default_style]
        }
      end

      return Array.new if input_port_rows.empty? and output_port_rows.empty?

      indexed_ret = Hash.new
      input_port_rows.each do |r|
        id = r[:id]
        indexed_ret[id] ||= r.subset(:id, :display_name).merge(:input_port_links => Array.new, :output_port_links => Array.new)
        indexed_ret[id][:input_port_links] << r[:port_link]
      end
      output_port_rows.each do |r|
        id = r[:id]
        indexed_ret[id] ||= r.subset(:id, :display_name).merge(:output_port_links => Array.new, :output_port_links => Array.new)
        indexed_ret[id][:output_port_links] << r[:port_link]
      end
      indexed_ret.values
    end

    def self.get_output_attrs_to_l4_input_ports(id_handles)
      rows = get_objs_in_set(id_handles,{:cols => [:output_attrs_to_l4_input_ports]},{:keep_ref_cols => true})
      return Hash.new if rows.empty?
      #restructure so that get mapping from attribute_id to port
      ret = Hash.new
      rows.each do |row|
        attr_id = row[:port_external_output][:external_attribute_id]
        ret[attr_id] ||= Array.new
        ret[attr_id] << row[:port_l4_input]
      end
      ret
    end

    def self.get_violations(id_handles)
      get_objs_in_set(id_handles,{:cols => [:violations]}).map{|r|r[:violation]}
    end

    def get_ui_info(datacenter)
      datacenter_id_sym = datacenter[:id].to_s.to_sym
      node_id_sym = self[:id].to_s.to_sym
      #TODO: hack assumes that canm just take position from first node[:u1]
      ((datacenter[:ui]||{})[:items]||{})[node_id_sym] || (self[:ui]||{})[datacenter_id_sym] || (self[:ui]||{}).values.first
    end

    def update_ui_info!(ui,datacenter)
      datacenter_id_sym = datacenter[:id].to_s.to_sym
      node_id_sym = self[:id].to_s.to_sym
      self[:ui] ||= Hash.new
      self[:ui][datacenter_id_sym] = ui
    end

    def get_users()
      node_user_list = get_objects_from_sp_hash(:columns => [:users])
      user_list = Array.new
      #TODO: just putting in username, not uid or gid
      node_user_list.map do |u|
        attr = u[:attribute]
        val = attr[:value_asserted]||attr[:value_derived]
        (val and attr[:display_name] == "username") ? {:id => attr[:id], :username => val, :avatar_filename => 'generic-user-male.png'} : nil 
      end.compact
    end

    def get_applications()
      app_hash_list = get_objects_col_from_sp_hash({:columns => [:applications]},:component)

      i18n = get_i18n_mappings_for_models(:component)
      app_hash_list.map do |component|
        name = component[:display_name]
        cmp_i18n = i18n_string(i18n,:component,name)
        component_el = {:id => component[:id], :name =>  name, :i18n => cmp_i18n}
        component_icon_fn = ((component[:ui]||{})[:images]||{})[:tnail]
        component_el.merge(component_icon_fn ? {:component_icon_filename => component_icon_fn} : {})
      end
    end

    def get_node_service_checks()
      return Array.new if get_objects_from_sp_hash(:columns => [:monitoring_agents]).empty?

      #TODO: i18n treatment of service check names
      get_objects_col_from_sp_hash({:columns => [:monitoring_items__node]},:monitoring_item)
    end
    def get_component_service_checks()
      return Array.new if get_objects_from_sp_hash(:columns => [:monitoring_agents]).empty?
      #TODO: i18n treatment of service check names
      i18n = get_i18n_mappings_for_models(:component)

      get_objects_from_sp_hash(:columns => [:monitoring_items__component]).map do |r|
        cmp_name = r[:component][:display_name]
        cmp_info = {:component_name => cmp_name,:component_i18n => i18n_string(i18n,:component,cmp_name) }
        r[:monitoring_item].merge(cmp_info)
      end
    end

    #returns external attribute links and port links
    #returns [connected_links,dangling_links]
    def self.get_external_connected_links(id_handles)
      port_link_ret = get_conn_port_links(id_handles)
      attr_link_ret = get_conn_external_attr_links(id_handles)
      [port_link_ret[0]+attr_link_ret[0],port_link_ret[1]+attr_link_ret[1]]
    end

    #return ports links 
    #returns [connected_links,dangling_links]
    def self.get_conn_port_links(id_handles)
      ret = [Array.new,Array.new]

      in_port_cols = [:id, :display_name, :input_port_links]
      ndx_in_links = Hash.new
      get_objs_in_set(id_handles,:columns => in_port_cols).each do |r|
        link = r[:port_link]
        ndx_in_links[link[:id]] = link 
      end

      out_port_cols = [:id, :display_name, :output_port_links]
      ndx_out_links = Hash.new
      get_objs_in_set(id_handles,:columns => out_port_cols).each do |r|
        link = r[:port_link]
        ndx_out_links[link[:id]] = link 
      end

      return ret if ndx_in_links.empty? and ndx_out_links.empty?

      connected_links = (ndx_in_links.keys & ndx_out_links.keys).map{|id|ndx_in_links[id]}

      dangling_links = (ndx_in_links.keys - ndx_out_links.keys).map{|id|ndx_in_links[id]}
      dangling_links += (ndx_out_links.keys - ndx_in_links.keys).map{|id|ndx_out_links[id]}
      [connected_links,dangling_links]
    end

    #return externally connected attribute links
    #returns [connected_links,dangling_links]
    def self.get_conn_external_attr_links(id_handles)
      ret = [Array.new,Array.new]

      in_port_cols = [:id, :display_name, :input_attribute_links]
      ndx_in_links = Hash.new
      get_objs_in_set(id_handles,:columns => in_port_cols).each do |r|
        link = r[:attribute_link]
        ndx_in_links[link[:id]] = link if link[:type] == "external"
      end

      out_port_cols = [:id, :display_name, :output_attribute_links]
      ndx_out_links = Hash.new
      get_objs_in_set(id_handles,:columns => out_port_cols).each do |r|
        link = r[:attribute_link]
        ndx_out_links[link[:id]] = link if link[:type] == "external"
      end

      return ret if ndx_in_links.empty? and ndx_out_links.empty?

      connected_links = (ndx_in_links.keys & ndx_out_links.keys).map{|id|ndx_in_links[id]}

      dangling_links = (ndx_in_links.keys - ndx_out_links.keys).map{|id|ndx_in_links[id]}
      dangling_links += (ndx_out_links.keys - ndx_in_links.keys).map{|id|ndx_out_links[id]}
      [connected_links,dangling_links]
    end

    ################## cloning related methods
    def add_model_specific_override_attrs!(override_attrs,target_obj)
      override_attrs[:type] ||= "staged"
      override_attrs[:ref] ||= SQL::ColRef.concat("s-",:ref)
      override_attrs[:display_name] ||= SQL::ColRef.concat{|o|["s-",:display_name,o.case{[[{:ref_num=> nil},""],o.concat("-",:ref_num)]}]}
    end
    def source_clone_info_opts()
      {:ret_new_obj_with_cols => [:id,:external_ref]}
    end

    def clone_post_copy_hook(clone_copy_output,opts={})
      component = clone_copy_output.objects.first
      #handles copying over if needed component template and implementation into project
      component.clone_post_copy_hook_into_node(self)

      component_idh = clone_copy_output.id_handles.first
     #TODO: deprecated create_needed_l4_sap_attributes(component_idh)

      #get the link defs/component_ports associated with components on the node; this is used
      #to determine if need to add internal links and for port processing
      node_link_defs_info = get_objs(:cols => [:node_link_defs_info])
      component_id = component.id()
      
      ###create needed component ports
      ndx_for_port_update = Hash.new
      component_link_defs = node_link_defs_info.map  do |r|
        link_def = r[:link_def]
        if link_def[:component_component_id] == component_id
          ndx_for_port_update[link_def[:id]] = r
          link_def 
        end
      end.compact

      create_opts = {:returning_sql_cols => [:link_def_id,:id,:display_name,:type,:connected]}
      new_cmp_ports = Port.create_needed_component_ports(component_link_defs,self,component,create_opts)

      #update node_link_defs_info with new ports
      new_cmp_ports.each do |port|
        ndx_for_port_update[port[:link_def_id]].merge!(:port => port)
      end

      #TODO: more efficient way to do this; instead include all needed columns in :returning_sql_cols above
      if opts[:outermost_ports] 
        port_mh = model_handle(:port)
        external_port_idhs = new_cmp_ports.map do |port_hash|
          port_mh.createIDH(:id => port_hash[:id]) if ["component_internal_external","component_external"].include?(port_hash[:type])
        end.compact
        unless external_port_idhs.empty?
          new_ports = Model.get_objs_in_set(external_port_idhs, {:cols => Port.common_columns})
          i18n = get_i18n_mappings_for_models(:component,:attribute)
          new_ports.map do |port|
            port.materialize!(Port.common_columns)
            port[:name] = get_i18n_port_name(i18n,port)
          end
          opts[:outermost_ports] += new_ports
        end
      end

      #### end create needed component ports ####
                                                             
      LinkDef.create_needed_internal_links(self,component,node_link_defs_info)

      #TODO: pass node_link_defs into create_component_external_ports?
      #TODO: deprecate beloww for above
      #Port.create_ports_for_external_attributes(id_handle,component_idh)
      parent_action_id_handle = get_parent_id_handle()
      StateChange.create_pending_change_item(:new_item => component_idh, :parent => parent_action_id_handle)
    end

    #TODO: quick hack
    def self.get_wspace_display(id_handle)
      node_id = IDInfoTable.get_id_from_id_handle(id_handle)
      node_mh = id_handle.createMH(:model_name => :node)
      node = get_objects(node_mh,{:id => node_id}).first

      component_mh = node_mh.createMH(:model_name => :component)
      component_ds = get_objects_just_dataset(component_mh,{:node_node_id => node_id})
      attr_where_clause = {:is_port => true}
      #TODO: can prune what fields included
      attr_fs = Model::FieldSet.default(:attribute).with_added_cols(:component_component_id)
      attribute_mh = node_mh.createMH(:model_name => :attribute)
      attribute_ds = get_objects_just_dataset(attribute_mh,attr_where_clause,FieldSet.opt(attr_fs))
      components = component_ds.graph(:left_outer,attribute_ds,{:component_component_id => :id}).all
      node.merge(:component => components)
    end
    #######################
#TODO: may be aqble to deprecate most or all of below
      ### helpers
      def ds_attributes(attr_list)
        [:ds_attributes]
      end
      #TODO: rename subobject to sub_object
      def is_ds_subobject?(relation_type)
        false
      end


      ##### Actions
#TODO: need tp fix up below
      def self.get_node_attribute_values(id_handle,opts={})
	c = id_handle[:c]
        node_obj = get_object(id_handle,opts)
        raise Error.new("node associated with (#{id_handle}) not found") if node_obj.nil? 	
	ret = node_obj.get_direct_attribute_values(:value) || {}

	cmps = node_obj.get_objects_associated_components()
	cmps.each{|cmp|
	  ret[:component]||= {}
	  cmp_ref = cmp.get_qualified_ref.to_sym
	  ret[:component][cmp_ref] = 
	    cmp[:external_ref] ? {:external_ref => cmp[:external_ref]} : {}
	  values = cmp.get_direct_attribute_values(:value,{:attr_include => [:external_ref]})
	  ret[:component][cmp_ref][:attribute] = values if values 
        }
        ret
      end

    #######

#TODO: should this be more generic and centralized?
    def get_objects_associated_components()
      assocs = Model.get_objects(ModelHandle.new(@c,:assoc_node_component),:node_id => self[:id])
      return [] if assocs.nil?
      assocs.map{|assoc|Model.get_object(IDHandle[:c=>@c,:guid => assoc[:component_id]])}
    end

#TODO: should be centralized
    def get_contained_attribute_ids(opts={})
      get_directly_contained_object_ids(:attribute)||[]
    end

    def get_direct_attribute_values(type,opts={})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      attr_val_array = Model.get_objects(ModelHandle.new(@c,:attribute),nil,:parent_id => parent_id)
      return nil if attr_val_array.nil?
      return nil if attr_val_array.empty?
      hash_values = {}
      attr_type = {:asserted => :value_asserted, :derived => :value_derived, :value => :attribute_value}[type]
      attr_val_array.each{|attr|
        hash_values[attr.get_qualified_ref.to_sym] =
          {:value => attr[attr_type],:id => attr[:id]}
      }
      {:attribute => hash_values}
    end

    def get_obj_with_common_cols()
      common_cols =  self.class.common_columns()
      ret = get_objs(:cols => common_cols).first
      ret.materialize!(common_cols)
    end

  end
end

module XYZ
  class NodeInterface < Model
#    set_relation_name(:node,:interface)

    ### object access functions
    #######################
  end
end



