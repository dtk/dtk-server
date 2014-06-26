#    set_relation_name(:state,:state_change)
    def self.up()
      column :status, :varchar, :size => 15, :default => "pending" #  | "completed" TODO: may have  "executing" 
      column :type, :varchar, :size => 25# "setting" | "create-node" | "install_component" ?? "delete" | "patch-component" | "upgrade-component" | "rollback-component" 
      column :base_object, :json
      # TODO; may rename
      column :object_type, :varchar, :size => 15 # "attribute" | "node" | "component"

      column :change, :json # gives detail about the change

      virtual_column :parent_name, :possible_parents => [:datacenter,:state_change]
      virtual_column :old_value, :path => [:change, :old]
      virtual_column :new_value, :path => [:change, :new]

      virtual_column :qualified_parent_name, :type => :varchar, :local_dependencies => [:base_object]

      # one of thse wil be non null and point to object being changed or added
      foreign_key :node_id, :node, FK_CASCADE_OPT
      foreign_key :attribute_id, :attribute, FK_CASCADE_OPT
      foreign_key :component_id, :component, FK_CASCADE_OPT
      # TODO: may have here who, when

      # TODO: example converted form; apply to rest of vcs
      virtual_column :created_node,:type => :json, :hidden => true,
        :remote_dependencies =>
        [
         {
           :model_name => :node,
           :join_type => :inner,
           :join_cond=>{:id=> q(:state_change,:node_id)},
           :cols=>[:id, :display_name, :external_ref, id(:datacenter),:ancestor_id]
         },
         {
           :model_name => :datacenter,
           :join_type => :inner,
           :join_cond=>{:id=> p(:node,:datacenter)},
           :cols=>[:id, :display_name]
         },
         {
           :model_name => :node,
           :alias => :image,
           :join_type => :inner,
           :join_cond=>{:id=> q(:node,:ancestor_id)},
           :cols=>[:id, :display_name,:external_ref]
         }
        ]

      component_same_type = {
        # TODO: below used to handle situation where multiple isnatnces of recipe appear on same node
        # and all parameters forming list is needed
         # TODO: extend to allow join condition that has not so pruning out component_same_type
        :model_name => :component,
        :alias => :component_same_type,
        :filter => [:and, [:eq, :only_one_per_node, false]],
        :join_type => :left_outer,
        # TODO: need to extend code so can use p and id in statements below
        :join_cond=>{:external_ref=> q(:component,:external_ref), :node_node_id => p(:component,:node)},
        :cols=>[:id, :display_name, :external_ref, id(:node), :only_one_per_node]
      }
      node = 
        {
        :model_name => :node,
        :join_type => :inner,
        :join_cond=>{:id=> p(:component,:node)},
        :cols=>[:id, :display_name, :external_ref]
      }
      virtual_column :installed_component, :type => :json, :hidden => true,
        :remote_dependencies =>
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> q(:state_change,:component_id)},
           :cols=>[:id, :display_name, :basic_type, :external_ref, id(:node), :only_one_per_node]
         },
         node,
         component_same_type 
        ]

      virtual_column :changed_attribute, :type => :json, :hidden => true,
        :remote_dependencies =>
        [
         {
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=> {:id => q(:state_change,:attribute_id)},
           :cols=>[:id, id(:component),:display_name,:value_asserted]
         },
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> p(:attribute,:component)},
           :cols=>[:id, :display_name, :basic_type, :external_ref, id(:node), :only_one_per_node]
         },
         node,
         component_same_type
        ]

      many_to_one :datacenter, :state_change
      one_to_many :state_change #that is for decomposition 
    end
