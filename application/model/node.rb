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

      virtual_column :attribute_ports, :type => :json, :hidden => true, 
      :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name, :component_type, id(:node)]
         },
         {
           :model_name => :attribute,
           :convert => true,
           :join_type => :inner,
           :filter => [:and,[:eq,:is_port,true]],
           :join_cond=>{:component_component_id => q(:component,:id)},
           :cols => [:id,:display_name, id(:component),:is_port,:semantic_type_summary,:description]
         }]


      attribute_ports_for_links =   
        [{
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name, id(:node)]
         },
         {
           :model_name => :attribute,
           :join_type => :inner,
           :filter => [:and,[:eq,:is_port,true]],
           :join_cond=>{:component_component_id => q(:component,:id)},
           :cols => [:id,:display_name, id(:component)]
         }]


      virtual_column :input_port_links, :type => :json, :hidden => true, 
      :remote_dependencies => 
        attribute_ports_for_links +
        [{
           :model_name => :attribute_link,
           :convert => true,
           :join_cond=>{:input_id =>q(:attribute,:id)},
           :join_type => :inner,
           :cols => [:id,:type,:input_id,:output_id,id(:node),:hidden]
         },
         {
           :model_name => :attribute,
           :alias => :attr_other_end,
           :convert => true,
           :join_cond=>{:id =>q(:attribute_link,:output_id)},
           :join_type => :inner,
           :cols => [:id,:display_name]
         }]

      virtual_column :output_port_links, :type => :json, :hidden => true, 
      :remote_dependencies => 
        attribute_ports_for_links +
        [{
           :model_name => :attribute_link,
           :convert => true,
           :join_cond=>{:output_id =>q(:attribute,:id)},
           :join_type => :inner,
           :cols => [:id,:type,:input_id,:output_id,id(:node),:hidden]
         },
         {
           :model_name => :attribute,
           :alias => :attr_other_end,
           :convert => true,
           :join_cond=>{:id =>q(:attribute_link,:input_id)},
           :join_type => :inner,
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
    def get_virtual_attribute(attribute_name,cols,field_to_match=:display_name)
      sp_hash = {
        :model_name => :attribute,
        :filter => [:eq, field_to_match, attribute_name],
        :cols => cols
      }
      get_children_from_sp_hash(:attribute,sp_hash).first
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

    def get_ports(type=nil)
      port_list = PortList.create(type,[id_handle])

      attr_port_rows = get_objects_from_sp_hash(:columns => [:attribute_ports])

      i18n = get_i18n_mappings_for_models(:component,:attribute)

      pruned_attr_port_rows = attr_port_rows.reject{|r| r[:attribute].nil? or port_list.attr_is_pruned?(r[:attribute])}
      return Array.new if pruned_attr_port_rows.empty?
      #to allow group procesisng of needed info

      pruned_attr_port_rows.each do |r|
        attr = r[:attribute]
        cmp = r[:component]||{}
        attr_name = attr[:display_name]
        cmp_name = cmp[:display_name]
        attr[:display_name] =  get_i18n_port_name(i18n,attr_name,cmp_name) if attr_name and cmp_name
        #TODO: hack to remove description
        attr[:description] = ""
        port_list.add_or_collapse_attribute!(attr,cmp)
      end

      port_list_top_level = port_list.top_level()
      Model::materialize_virtual_columns!(port_list_top_level,[:port_type])
      port_list_top_level
    end

    def self.get_port_links(id_handles,type="l4")
      port_list = PortList.create(type)

      input_port_rows = port_list.get_input_port_link_info(id_handles)
      output_port_rows = port_list.get_output_port_link_info(id_handles)

      i18n = get_i18n_mappings_for_models(:component,:attribute)
      return Array.new if input_port_rows.empty? and output_port_rows.empty?
      indexed_ret = Hash.new
      input_port_rows.each do |r|
        id = r[:id]
        indexed_ret[id] ||= r.subset(:id, :display_name).merge(:input_port_links => Array.new, :output_port_links => Array.new)
        port_i18n = get_i18n_port_name(i18n,r[:attribute][:display_name],r[:component][:display_name])
        indexed_ret[id][:input_port_links] << r[:attribute_link].merge(:port_i18n => port_i18n)
      end
      output_port_rows.each do |r|
        id = r[:id]
        indexed_ret[id] ||= r.subset(:id, :display_name).merge(:output_port_links => Array.new, :output_port_links => Array.new)
        port_i18n = get_i18n_port_name(i18n,r[:attribute][:display_name],r[:component][:display_name])
        indexed_ret[id][:output_port_links] << r[:attribute_link].merge(:port_i18n => port_i18n)
      end
      indexed_ret.values
    end

    #returns [connected_links,dangling_links]
    def self.get_external_connected_port_links(id_handles)
      ret = [Array.new,Array.new]

      in_port_cols = [:id, :display_name, :input_port_links]
      ndx_in_links = Hash.new
      get_objects_in_set_from_sp_hash(id_handles,:columns => in_port_cols).each do |r|
        link = r[:attribute_link]
        ndx_in_links[link[:id]] = link if link[:type] == "external"
      end

      out_port_cols = [:id, :display_name, :output_port_links]
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
      Port.create_external_ports(id_handle,cmp_id_handle)
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



