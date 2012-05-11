#TODO: temp until move into meta directory
module XYZ
  module NodeMetaClassMixin 
    def up()
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
      foreign_key :node_binding_id, :node_binding, FK_SET_NULL_OPT
      virtual_column :target_id, :type => ID_TYPES[:id], :local_dependencies => [:datacenter_datacenter_id]
      virtual_column :parent_name, :possible_parents => [:library,:datacenter]
      virtual_column :disk_size, :path => [:ds_attributes,:flavor,:disk] #in megs
      #TODO how to have this conditionally "show up"
      virtual_column :ec2_security_groups, :path => [:ds_attributes,:groups] 

      #can be null; points to the canonical member (a node template in the library) which is used by default when do node_group add_node 
      foreign_key :canonical_template_node_id, :node, FK_SET_NULL_OPT
      virtual_column :canonical_template_node, :type => :json, :hidden => true,
        :remote_dependencies =>
        [{
           :model_name => :node,
           :alias => :template_node,
           :convert => true,
           :join_type => :inner,
           :join_cond => {:id => q(:node,:canonical_template_node_id)},
           :cols => [:id,:group_id, :display_name]
         }]

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

      virtual_column :library, :type => :json, :hidden => true,
        :remote_dependencies =>
        [{
           :model_name => :library,
           :join_type => :inner,
           :join_cond => {:id => p(:node,:library)},
           :cols => [:id,:display_name]
         }]

      virtual_column :node_or_ng_summary, :type=>:json, :hidden=>true,
      :remote_dependencies=>
        [{
           :model_name=>:node_group_relation,
           :join_type=>:left_outer,
           :join_cond=>{:node_group_id => q(:node,:id)},
           :cols=>[:id,:display_name,:node_id]
       },
       {
           :model_name=>:node,
           :alias => :node_member,
           :convert => true,
           :join_type=>:left_outer,
           :join_cond=>{:id => q(:node_group_relation,:node_id)},
           :cols=>[:id,:display_name,:type]
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




      node_attrs_on_node_def = 
        [{
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name]
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
      virtual_column :input_attribute_links_cmp, :type => :json, :hidden => true, 
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
      virtual_column :input_attribute_links_node, :type => :json, :hidden => true, 
      :remote_dependencies => 
        node_attrs_on_node_def +
        [
         {
           :model_name => :attribute_link,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:input_id => q(:attribute,:id)},
           :cols => [:id,:display_name, :type, :input_id,:output_id]
         }]
      virtual_column :output_attribute_links_cmp, :type => :json, :hidden => true, 
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
      virtual_column :output_attribute_links_node, :type => :json, :hidden => true, 
      :remote_dependencies => 
        node_attrs_on_node_def +
        [
         {
           :model_name => :attribute_link,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:output_id => q(:attribute,:id)},
           :cols => [:id,:display_name, :type, :input_id,:output_id]
         }]

      #used when node is deleted to find and update dangling attribute links
      for_dangling_links =
        [{
           :model_name => :attribute_link,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:output_id => q(:output_attribute,:id)},
           :cols => [:id, :type, :input_id,:index_map]
         },
         {
           :model_name => :attribute,
           :alias => :input_attribute,
           :join_type => :inner,
           :join_cond=>{:id => q(:attribute_link,:input_id)},
           :cols => [:id,:display_name,:value_derived]
         },
         {
           :model_name => :attribute_link,
           :alias => :all_input_links,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:input_id => q(:attribute_link,:input_id)},
           :cols => [:id,:type, :input_id,:index_map]
         }]
      virtual_column :dangling_input_links_from_components, :type => :json, :hidden => true, 
      :remote_dependencies => 
        [{
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name, :component_type, id(:node)]
         },
         {
           :model_name => :attribute,
           :alias => :output_attribute,
           :join_type => :inner,
           :join_cond=>{:component_component_id => q(:component,:id)},
           :cols => [:id,:display_name]
         }] + for_dangling_links

      virtual_column :dangling_input_links_from_nodes, :type => :json, :hidden => true, 
      :remote_dependencies => 
         [{
           :model_name => :attribute,
           :alias => :output_attribute,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => [:id,:display_name]
          }] + for_dangling_links

      ##### end of for connection to ports and port links

      virtual_column :components, :type => :json, :hidden => true,
      :remote_dependencies =>
        [
         {
           :model_name => :component,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:node_node_id =>:node__id},
           :cols => [:id,:display_name,:group_id]
         }]

      virtual_column :cmps_for_clone_into_node, :type => :json, :hidden => true,
      :remote_dependencies =>
        [
         {
           :model_name => :component,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:node_node_id =>:node__id},
           :filter => [:eq, :from_on_create_event, false],
           :cols => [:id,:display_name,:dependencies, :extended_base, :component_type] #columns needed by Component.find_component_dependencies
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

      set_submodel(:node_group)
    end
  end
end
