
{
  :impelements_owner=>true,
  :has_ancestor_fields=>true,
  :field_defs=>{
    :display_name=>{
        :type=>:text,
        :size=>50
    },
    :parent_name=>{
        :type=>:text
    },
    :type=>{
        :type=>:select,
        :size=>15
    },
    :basic_type=>{
        :type=>:select,
        :size=>15
    },
    :only_one_per_node=>{
        :type=>:boolean,
    },
    :version=>{
        :type=>:text,
        :size=>25,
    },
    :uri=>{
        :type=>:text,
    },
    :ui=>{
        :type=>:json,
    },
  },
  :relationships=>{
  }
}

=begin
         has_ancestor_field()
        ds_column_defs :ds_attributes, :ds_key
        external_ref_column_defs()
        column :type, :varchar, :size => 15 # instance | template | composite
        column :basic_type, :varchar, :size => 15 # service | package | language | ..
        column :only_one_per_node, :boolean, :default => true
        column :version, :varchar, :size => 25 # version of underlying component (not chef recipe .... version)
        column :uri, :varchar
        column :ui, :json
        #constraint_node_id is used when items in library to point to a node of type contraint or contraint-common-node
        #in library parent niode is used to link to image
        #in datacenter constraint_node_id will be null and if parent is a node it will have type instance or staged
        foreign_key :constraint_node_id, :node, FK_SET_NULL_OPT
        virtual_column :parent_name, :possible_parents => [:component,:library,:node,:node_group,:project]
        many_to_one :component, :library, :node, :node_group, :project
        one_to_many :component, :attribute_link, :attribute, :monitoring_item

=end
