#TODO: temp until move into meta directory
module XYZ
  module ComponentMetaClassMixin
    def up()
      ds_column_defs :ds_attributes, :ds_key
      external_ref_column_defs()
      virtual_column :name, :type => :varchar, :local_dependencies => [:display_name]
      virtual_column :config_agent_type, :type => :string, :local_dependencies => [:external_ref]
      
      #columns related to name/labels
      #specfic labels of components and its attributes
      column :keys, :json #only used if only_one_per_node is false; array of keys for displaying component name
      column :i18n_labels, :json, :ret_keys_as_symbols => false
      
      #columns related to version
      column :version, :varchar, :size => 25, :default => "0.0.1" # version of underlying component (not chef recipe .... version)
      column :updated, :boolean, :default => false

      #columns related to type
      column :type, :varchar, :size => 15, :default => "template" # instance | composite | template
      #top level in component type hiererarchy
      column :basic_type, :varchar, :size => 25 #service, application, language, application, extension, database, user
      #leaf type in component type 
      column :specific_type, :varchar, :size => 30 
      column :component_type, :varchar, :size => 50 #this is the exact component type; two instances taht share this can differ by things like defaults

      #if set to true only one instance of a component (using component_type to determine 'same') can be on a node
      column :only_one_per_node, :boolean, :default => true
      #refernce used when multiple isnatnces of same component type 
      #TODO: make sure that this is preserved under clone; case to watch out fro is when cloning for example more dbs in something with dbs
      virtual_column :multiple_instance_ref, :type => :integer ,:local_dependencies => [:ref_num]

      #used when this component is an extension
      column :extended_base, :varchar, :size => 30
      virtual_column :extended_base_id, :type => ID_TYPES[:id] ,:local_dependencies => [:extended_base,:implementation_id]
      virtual_column :instance_extended_base_id, :type => ID_TYPES[:id] ,:local_dependencies => [:extended_base,:implementation_id,:node_node_id]
        column :extension_type, :varchar, :size => 30

      column :uri, :varchar
      column :ui, :json
        #:assembly_id (in contrast to parent field :component_id) is for tieing teh component to a composite component which is not a container
      foreign_key :assembly_id, :component, FK_SET_NULL_OPT
      column :view_def_ref, :varchar

      #TODO: change if multiple implementations per component
      foreign_key :implementation_id, :implementation, FK_SET_NULL_OPT

      column :link_defs, :json
      #deprecate below for above
      #TODO: for efficiency materialize and if so have two variants of :component_parent for attribute; one for input, which brings in :connectivity_profile and other for output which deos not
      virtual_column :link_defs_external, :type => :json, :local_dependencies => [:link_defs,:component_type,:specific_type,:basic_type]
      virtual_column :connectivity_profile_internal, :type => :json, :local_dependencies => [:link_defs,:component_type,:specific_type,:basic_type]
      virtual_column :most_specific_type, :type => :varchar, :local_dependencies => [:specific_type,:basic_type]

      many_to_one :component, :library, :node, :datacenter, :project
      one_to_many :component, :attribute_link, :attribute, :port_link, :monitoring_item, :dependency, :layout, :file_asset, :link_def
      one_to_many_clone_omit :layout

      virtual_column :project_id, :type => ID_TYPES[:id], :local_dependencies => [:project_project_id]
      virtual_column :node_id, :type => ID_TYPES[:id], :local_dependencies => [:node_node_id]
      virtual_column :library_id, :type => ID_TYPES[:id], :local_dependencies => [:library_library_id]
      virtual_column :parent_name, :possible_parents => [:component,:library,:node,:project]

      virtual_column :view_def_key, :type => :varchar, :hidden => true, :local_dependencies => [:id,:view_def_ref,:component_type] 

      ###### virtual columns related to attributes
        attributes_def =  {
          :model_name => :attribute,
          :join_type => :left_outer,
          :convert => true,
          :join_cond=>{:component_component_id => q(:component,:id)} #TODO: want to use p(:component,:attribute) on left hand side
        }

        virtual_column :attributes, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [attributes_def.merge(
           :cols => [:id,:display_name,:hidden,:description,id(:component),:attribute_value,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change]
        )]

        virtual_column :attributes_view_def_info, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [attributes_def.merge(
           :filter => [:eq, :hidden, false],
           :cols => [:id,:display_name,:view_def_key,id(:component),:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change]
         )]

        virtual_column :attributes_ports, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [attributes_def.merge(
           :filter => [:eq, :is_port, true],
           :cols => [:id,:display_name,id(:component),:port_is_external,:port_type,:port_location]
         )]


      virtual_column :dynamic_attributes, :type => :json, :hidden => true,
        :remote_dependencies =>
        [
         { :model_name => :attribute,
           :convert => true,
           :join_type => :inner,
           :filter => [:eq,:dynamic, true],
           :join_cond=>{:component_component_id => q(:component,:id)} ,
           :cols => [:id,:group_id,:display_name]
         }]

      ###### end of virtual columns related to attributes, ports, and link_defs
      virtual_column :node_assembly_nested_nodes_and_cmps, :type => :json, :hidden => true,
       :remote_dependencies =>
        [
         {
           :model_name => :node,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:assembly_id => q(:component,:id)},
           :cols => Node.common_columns
         },
         {
           :model_name => :component,
           :convert => true,
           :alias => :nested_component,
           :join_type => :inner,
           :join_cond=>{:node_node_id => q(:node,:id)},
           :cols => Component.common_columns
         }]


      virtual_column :implementation_file_paths, :type => :json, :hidden => true,
      :remote_dependencies =>
        [
         {
           :model_name => :implementation,
           :join_type => :inner,
           :join_cond=>{:id => q(:component,:implementation_id)},
           :cols => [:id,:display_name,:type]
         },
         {
           :model_name => :file_asset,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:implementation_implementation_id => q(:implementation,:id)},
           :cols => [:id,:file_name,:type,:path]
         }]

        virtual_column :dependencies, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :dependency,
           :alias => :dependencies,
           :convert => true,
           :join_type => :left_outer,
           :join_cond=>{:component_component_id => q(:component,:id)}, 
           :cols => [:id,:search_pattern,:type,:description,:severity]
         }
        ]

        node_assembly_parts = {
          :model_name => :node,
          :join_type => :inner,
          :join_cond=>{:assembly_id => q(:component,:id)},
          :cols => [:id,:display_name,:assembly_id]
        }


        virtual_column :node_assembly_parts, :type => :json, :hidden => true,
        :remote_dependencies => [node_assembly_parts]

        virtual_column :node_assembly_parts_node_attrs, :type => :json, :hidden => true,
        :remote_dependencies => 
          [
           node_assembly_parts,
           {
             :model_name => :attribute,
             :convert => true,
             :join_type => :inner,
             :join_cond=>{:node_node_id => q(:node,:id)},
             :cols => [:id,:display_name,:dynamic,:attribute_value]
           }
          ]
        virtual_column :node_assembly_parts_cmp_attrs, :type => :json, :hidden => true,
        :remote_dependencies => 
          [
           node_assembly_parts,
           {
             :model_name => :component,
             :alias => :component_part,
             :join_type => :inner,
             :join_cond=>{:node_node_id => q(:node,:id)},
             :cols => [:id]
           },
           {
             :model_name => :attribute,
             :convert => true,
             :join_type => :inner,
             :join_cond=>{:component_component_id => q(:component_part,:id)},
             :cols => [:id,:display_name,:dynamic,:attribute_value]
           }
          ]

        virtual_column :containing_node_id_info, :type => :json, :hidden => true,
         :remote_dependencies =>
         [
          {
            :model_name => :component,
            :alias => :parent_component,
            :join_type => :left_outer,
            :join_cond=>{:id => p(:component,:component)},
            :cols => [:id,:display_name,id(:node)]
          }
         ]

        virtual_column :has_pending_change, :type => :boolean, :hidden => true,
         :remote_dependencies =>
         [
          {
            :model_name => :state_change,
            #TODO: avoiding use of :component_component
            :sequel_def => lambda{|ds|ds.where(:state => "pending").join(:attribute__attribute,{:id => :attribute_id}).group_and_count(:attribute__component_component_id)},
            :join_type => :left_outer,
            :join_cond=>{:component_component_id =>:component__id}
          },
          {
            :model_name => :state_change,
            :sequel_def => lambda{|ds|ds.where(:state => "pending").group_and_count(:component_id)},
            :join_type => :left_outer,
            :join_cond=>{:component_id =>:component__id}
            }
         ]

      #TODO: needs to be refined since now no node_group_id
        virtual_column :containing_datacenter, :type => :varchar, :hidden => true,
          :remote_dependencies =>
         [
          {
            :model_name => :datacenter,
            :alias => :datacenter_node,
            :sequel_def => lambda{|ds|ds.join_table(:right_outer,:node__node,{:datacenter_datacenter_id => :datacenter__id}).select({:node__id => :node_id},:datacenter__display_name)},
            :join_type => :left_outer,
            :join_cond=>{:node_id => p(:component,:node)}
          },
          {
            :model_name => :datacenter,
            :alias => :datacenter_node_group,
            :sequel_def => lambda{|ds|ds.join_table(:right_outer,:node__node_group,{:datacenter_datacenter_id => :datacenter__id}).select({:node_group__id => :node_group_id},:datacenter__display_name)},
            :join_type => :left_outer,
            :join_cond=>{:node_group_id => p(:component,:node_group)}
          },
          {
            :model_name => :datacenter,
            :alias => :datacenter_direct,
            :join_type => :left_outer,
            :join_cond=>{:id => p(:component,:datacenter)}
          }
         ]


        virtual_column :sap_dependency_database, :type => :json, :hidden => true,
        :remote_dependencies =>
          [{
             :model_name => :attribute,
             :convert => true,
             :filter => [:and, [:eq, :semantic_type_summary, "sap_config__db"]],
             :join_type => :inner,
             :join_cond=>{:component_component_id => q(:component,:id)},
             :cols => [:id,:display_name,:value_asserted,:value_derived,id(:component)]
           },
           {
             :model_name => :component,
             :alias => :parent_component,
             :join_type => :inner,
             :join_cond=>{:id => p(:component,:component)},
             :cols => [:id,:display_name,id(:node)]
           },
           {
             :model_name => :attribute,
             :alias => :parent_attribute,
             :convert => true,
             :filter => [:and, [:eq,:display_name,"sap__l4"]],
             :join_type => :inner,
             :join_cond=>{:component_component_id => q(:parent_component,:id)},
             :cols => [:id,:display_name,:value_asserted,:value_derived,id(:component)]
           },
           {
             :model_name => :node,
             :convert => true,
             :join_type => :inner,
             :join_cond=>{:id => :parent_component__node_node_id},
             :cols => [:id,:display_name]
           }
          ]

        
        virtual_column :layouts, :type => :json, :hidden => true,
        :remote_dependencies =>
          [{
             :model_name => :layout,
             :convert => true,
             :join_type => :inner,
             :join_cond=>{:component_component_id => q(:component,:id)},
             :cols => [:id,:display_name,id(:component),:def,:type,:is_active,:description,:updated_at]
           }]

        virtual_column :layouts_from_ancestor, :type => :json, :hidden => true,
        :remote_dependencies =>
          [{
             :model_name => :component,
             :alias => :template,
             :join_type => :inner,
             :join_cond=>{:id => q(:component,:ancestor_id)},
             :cols => [:id,:display_name]
           },
           {
             :model_name => :layout,
             :convert => true,
             :join_type => :inner,
             :join_cond=>{:component_component_id => q(:template,:id)},
             :cols => [:id,:display_name,id(:component),:def,:type,:is_active,:description,:updated_at]
           }]

        set_submodel(:assembly)
      end
end
end
