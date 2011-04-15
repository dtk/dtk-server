module XYZ
  class Node < Model
#    extend ClassMixinDataSourceExtensions
    set_relation_name(:node,:node)
#TODO: move this out into central model, should read off of model meta data for processing
    def self.up()
      ds_column_defs :ds_attributes, :ds_key, :data_source, :ds_source_obj_type
      external_ref_column_defs()

      column :tag, :varchar
      #TODO: may change types; by virtue of being in alibrary we know about item; may need to distingusih between backed images versus barbones one; also may only treat node constraints with search objects
      column :type, :varchar, :size => 25, :default => "instance" # | "image" | "staged" | "constraint" | "constraint-common-node"
      column :os, :varchar, :size => 25
      #TODO: is_deployed may just be a virtual column that tests if :external_ref is null
      column :is_deployed, :boolean
      column :architecture, :varchar, :size => 10 #e.g., 'i386'
      #TBD: in data source specfic now column :manifest, :varchar #e.g.,rnp-chef-server-0816-ubuntu-910-x86_32
      #TBD: experimenting whetehr better to make this actual or virtual columns
      column :image_size, :numeric, :size=>[8, 3] #in megs
      column :operational_status, :varchar, :size => 50
      column :ui, :json
      foreign_key :assembly_id, :component, FK_SET_NULL_OPT
      virtual_column :parent_name, :possible_parents => [:library,:datacenter]
      virtual_column :disk_size, :path => [:ds_attributes,:flavor,:disk] #in megs
      #TODO how to have this conditionally "show up"
      virtual_column :ec2_security_groups, :path => [:ds_attributes,:groups] 


      ##### for connection to ports and port links
      virtual_column :ports, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :port,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:type,id(:node),:containing_port_id,:external_attribute_id,:direction,:location,:ref]
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


      ##### end of for connection to ports and port links


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

    ### virtual column defs
    #######################
    #TODO: write as sql fn for efficiency
    def has_pending_change()
      ((self[:action]||{})[:count]||0) > 0
    end

    #######################
    ######### Model apis
    #attribute on node
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
        :cols => cols
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

    def self.get_ports(id_handles)
      get_objects_in_set_from_sp_hash(id_handles,{:cols => [:ports]},{:keep_ref_cols => true}).map{|r|r[:port]}
    end

    def get_ports(type=nil)
      port_list = self.class.get_ports([id_handle]).select do |port|
        type.nil? or 
          case type
            when "external" then port[:type] == "external"
            #if type is l4 return l4 ports and external ones not yet placed under a l4 port
            when "l4" then port[:type] == "l4" or (port[:type] == "external" and port[:containing_port_id].nil?)
          end
      end

      i18n = get_i18n_mappings_for_models(:component,:attribute)

      port_list.map do |port|
        {
          :description=>"",
          :is_port=>true, #TODO: probably not needed
          :location=> port[:location],
          :display_name=> get_i18n_port_name(i18n,port),
          :direction=> port[:direction], 
          :port_type=> port[:direction], #TODO: deprecate in favor of direction
          :id=> port[:id]
        }
      end
    end

    def self.get_port_links(id_handles,type="l4")
      raise Error.new("not implemented yet: get_port_links when type = #{type}") unless type == "l4"

      input_port_rows =  get_objects_in_set_from_sp_hash(id_handles,:columns => [:id, :display_name, :input_port_link_info]).select do |r|
        (r[:port]||{})[:type] == type
      end
      output_port_rows =  get_objects_in_set_from_sp_hash(id_handles,:columns => [:id, :display_name, :output_port_link_info]).select do |r|
        (r[:port]||{})[:type] == type
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
      rows = get_objects_in_set_from_sp_hash(id_handles,{:cols => [:output_attrs_to_l4_input_ports]},{:keep_ref_cols => true})
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
      get_objects_in_set_from_sp_hash(id_handles,{:cols => [:violations]}).map{|r|r[:violation]}
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
      get_objects_in_set_from_sp_hash(id_handles,:columns => in_port_cols).each do |r|
        link = r[:port_link]
        ndx_in_links[link[:id]] = link 
      end

      out_port_cols = [:id, :display_name, :output_port_links]
      ndx_out_links = Hash.new
      get_objects_in_set_from_sp_hash(id_handles,:columns => out_port_cols).each do |r|
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
      get_objects_in_set_from_sp_hash(id_handles,:columns => in_port_cols).each do |r|
        link = r[:attribute_link]
        ndx_in_links[link[:id]] = link if link[:type] == "external"
      end

      out_port_cols = [:id, :display_name, :output_attribute_links]
      ndx_out_links = Hash.new
      get_objects_in_set_from_sp_hash(id_handles,:columns => out_port_cols).each do |r|
        link = r[:attribute_link]
        ndx_out_links[link[:id]] = link if link[:type] == "external"
      end

      return ret if ndx_in_links.empty? and ndx_out_links.empty?

      connected_links = (ndx_in_links.keys & ndx_out_links.keys).map{|id|ndx_in_links[id]}

      dangling_links = (ndx_in_links.keys - ndx_out_links.keys).map{|id|ndx_in_links[id]}
      dangling_links += (ndx_out_links.keys - ndx_in_links.keys).map{|id|ndx_out_links[id]}
      [connected_links,dangling_links]
    end

    def add_model_specific_override_attrs!(override_attrs)
      override_attrs[:type] = "staged"
      override_attrs[:ref] = SQL::ColRef.concat("s-",:ref)
      override_attrs[:display_name] = SQL::ColRef.concat{|o|["s-",:display_name,o.case{[[{:ref_num=> nil},""],o.concat("-",:ref_num)]}]}
      override_attrs[:external_ref] = nil
    end

    def clone_post_copy_hook(clone_copy_output,opts={})
      cmp_id_handle = clone_copy_output.id_handles.first
      create_needed_l4_sap_attributes(cmp_id_handle)
      create_needed_additional_links(cmp_id_handle)
      Port.create_ports_for_external_attributes(id_handle,cmp_id_handle)
      parent_action_id_handle = get_parent_id_handle()
      StateChange.create_pending_change_item(:new_item => cmp_id_handle, :parent => parent_action_id_handle)
    end

    def create_needed_l4_sap_attributes(cmp_id_handle)
      ipv4_host_addrs_info = get_virtual_attribute("host_address_ipv4",[:id,:attribute_value],:semantic_type_summary)
      return nil unless ipv4_host_addrs_info
      ipv4_host_addrs = ipv4_host_addrs_info[:attribute_value]
      ipv4_host_addrs_idh = cmp_id_handle.createIDH({:id => ipv4_host_addrs_info[:id], :model_name => :attribute, :parent_model_name => :node})
      sap_config_attr_idh, new_sap_attr_idh = Attribute.create_needed_l4_sap_attributes(cmp_id_handle,ipv4_host_addrs)
      return nil unless new_sap_attr_idh
      AttributeLink.create_links_l4_sap(new_sap_attr_idh,sap_config_attr_idh,ipv4_host_addrs_idh,id_handle)
      new_sap_attr_idh
    end

    def create_needed_additional_links(cmp_id_handle)
      #TODO: more efficient would be to have clone object output have this info
      component = cmp_id_handle.create_object()
      conn_profile = component.get_objects_col_from_sp_hash({:cols => [:connectivity_profile_internal]}).first
      return unless conn_profile
      #get all other components on node
      sp_hash = {
        :model_name => :component,
        :filter => [:neq, :id, cmp_id_handle.get_id()],
        :cols => [:component_type,:most_specific_type]
      }
      other_cmps = get_children_from_sp_hash(:component,sp_hash)
      conn_info_list = conn_profile.match_other_components(other_cmps)
      return if conn_info_list.empty?
      parent_idh = cmp_id_handle.get_parent_id_handle

      conn_info_list.each do |conn_info|
        context = conn_info.get_context(component,conn_info[:other_component])
        (conn_info[:attribute_mappings]||[]).each do |attr_mapping|
          link = attr_mapping.ret_link(context)
          AttributeLink.create_attr_links(parent_idh,[link])
        end
      end
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
  end
end

module XYZ
  class NodeInterface < Model
#    set_relation_name(:node,:interface)

    ### object access functions
    #######################
  end
end



