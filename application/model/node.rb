module XYZ
  class Node < Model
#    extend ClassMixinDataSourceExtensions
    set_relation_name(:node,:node)
#TODO: move this out into central model, should read off of model meta data for processing
    def self.up()
      ds_column_defs :ds_attributes, :ds_key, :data_source, :ds_source_obj_type
      external_ref_column_defs()

      column :tag,  :varchar
      column :type, :varchar, :size => 25, :default => "instance" # | "image" | "staged" | "constraint" | "contraint-common-node"
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

      virtual_column :node_attributes, :type => :json, :hidden => true, 
      :remote_dependencies => 
        [
         {
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=>{:node_node_id =>:node__id},
           :cols => [:id,:display_name,:node_node_id,:value_derived,:value_asserted,:semantic_type_summary]
         }
        ]

      attribute_ports =   
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

      virtual_column :attribute_ports, :type => :json, :hidden => true, 
       :remote_dependencies => attribute_ports

      virtual_column :input_port_links, :type => :json, :hidden => true, 
      :remote_dependencies => 
        attribute_ports +
        [{
           :model_name => :attribute_link,
           :join_cond=>{:input_id =>q(:attribute,:id)},
           :join_type => :inner,
           :cols => [:id,:type,{:output_id => :other_end_output_id},:input_id,id(:node)]
         }]

      virtual_column :output_port_links, :type => :json, :hidden => true, 
      :remote_dependencies => 
        attribute_ports +
        [{
           :model_name => :attribute_link,
           :join_cond=>{:output_id =>q(:attribute,:id)},
           :join_type => :inner,
           :cols => [:id,:type,:hidden,{:input_id => :other_end_input_id},:output_id,id(:node)]
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
          }
         ]

      virtual_column :users, :type => :jsob, :hidden => true,
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

      #in dock 'applications means wider than basic_type == applicationsn
      applications =  {
        :model_name => :component,
        :join_type => :inner,
        :filter => [:or,
                    [:eq, :basic_type, "application"],
                    [:eq, :basic_type, "service"],
                    [:eq, :basic_type, "client"]],
        :join_cond=>{:node_node_id => q(:node,:id)},
        :cols=>[:id,:node_node_id,:display_name,:ui]
      }
      virtual_column :applications, :type => :jsob, :hidden => true,
      :remote_dependencies => [applications]
      virtual_column :applications_with_attrs, :type => :jsob, :hidden => true,
      :remote_dependencies => 
        [
         applications,
         {
           :model_name => :attribute,
           :join_type => :left_outer,
           :filter => [:and, [:eq, :hidden, false]], 
           :join_cond=>{:component_component_id => q(:component,:id)},
           :cols=>[:id,:component_component_id,:display_name,:value_asserted,:value_derived,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change]
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
      one_to_many :attribute, :attribute_link, :component, :node_interface, :address_access_point, :monitoring_item
    end

    ### virtual column defs
    #######################
    #TODO: write as sql fn for efficiency
    def has_pending_change()
      ((self[:action]||{})[:count]||0) > 0
    end

    #object processing and access functions
    def get_users()
      search_pattern_hash = {
        :columns => [:users]
      }
      
      node_user_list = get_objects_from_search_pattern_hash(search_pattern_hash)
      user_list = Array.new
      #TODO: just putting in username, not uid or gid
      node_user_list.map do |u|
        attr = u[:attribute]
        val = attr[:value_asserted]||attr[:value_derived]
        (val and attr[:display_name] == "username") ? {:id => attr[:id], :username => val, :avatar_filename => 'generic-user-male.png'} : nil 
      end.compact
    end

    def get_applications()
      search_pattern_hash = {
        :columns => [:applications]
      }
      node_app_list = get_objects_from_search_pattern_hash(search_pattern_hash)
      node_app_list.map{|r|r[:component]}.compact
    end

    def get_port_links()
      input_port_cols = [:id, :display_name, :input_port_links]
      input_port_rows = get_objects_from_search_pattern_hash(:columns => input_port_cols)
      output_port_cols = [:id, :display_name, :output_port_links]
      output_port_rows = get_objects_from_search_pattern_hash(:columns => output_port_cols)

      return Array.new if input_port_rows.empty? and output_port_rows.empty?
      #all node attrs will be the same ; so just using first as sample
      ret = (input_port_rows.first||output_port_rows.first).subset(:id, :display_name)
      ret[:input_port_links] = input_port_rows.map{|r|r[:attribute_link]}.compact
      ret[:output_port_links] = output_port_rows.map{|r|r[:attribute_link]}.compact
      ret
    end

    def self.add_model_specific_override_attrs!(override_attrs)
      override_attrs[:type] = "staged"
      override_attrs[:ref] = SQL::ColRef.concat("s-",:ref)
      override_attrs[:display_name] = SQL::ColRef.concat{|o|["s-",:display_name,o.case{[[{:ref_num=> nil},""],o.concat("-",:ref_num)]}]}
      override_attrs[:external_ref] = nil
    end

    def self.clone_post_copy_hook(clone_copy_output,target_id_handle,opts={})
      new_id_handle = clone_copy_output.id_handles.first
      add_needed_ipv4_sap_attributes(new_id_handle,target_id_handle)
      parent_action_id_handle = target_id_handle.get_parent_id_handle()
      StateChange.create_pending_change_item(:new_item => new_id_handle, :parent => parent_action_id_handle)
    end

    def self.add_needed_ipv4_sap_attributes(cmp_id_handle,node_id_handle)
      field_set = Model::FieldSet.new(:node,[:id,:node_attributes])
      filter = [:and, [:eq, :node__id, node_id_handle.get_id()]]
      #TDOO: might match on ref or semantic type instead
      global_wc = {:attribute__semantic_type_summary => "host_address_ipv4"}
      ds = SearchObject.create_from_field_set(field_set,cmp_id_handle[:c],filter).create_dataset().where(global_wc)

      ipv4_host_addrs_info = (ds.all.first||{})[:attribute]
      return nil unless ipv4_host_addrs_info
      ipv4_host_addrs = ipv4_host_addrs_info[:value_asserted]||ipv4_host_addrs_info[:value_derived]
      ipv4_host_addrs_idh = cmp_id_handle.createIDH({:guid => ipv4_host_addrs_info[:id], :model_name => :attribute, :parent_model_name => :node})
      sap_config_attr_idh, new_sap_attr_idh = Attribute.add_needed_ipv4_sap_attributes(cmp_id_handle,ipv4_host_addrs)
      return nil unless new_sap_attr_idh
      AttributeLink.create_links_ipv4_sap(new_sap_attr_idh,sap_config_attr_idh,ipv4_host_addrs_idh,node_id_handle)
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
    set_relation_name(:node,:interface)
    def self.up()
      column :type, :varchar, :size => 25 #ethernet, vlan, ...
      column :address, :json #e.g., {:family : "ipv4, :address : "10.4.5.7", "mask" : 255.255.255.0"}
      foreign_key :network_partition_id, :network_partition, FK_CASCADE_OPT
      many_to_one :node, :node_interface
      one_to_many :node_interface
    end
    ### virtual column defs
    #######################
    ### object access functions
    #######################
  end
end



