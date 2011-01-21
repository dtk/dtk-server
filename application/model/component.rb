module XYZ
  class Component < Model
    set_relation_name(:component,:component)
    class << self
      def up()
        ds_column_defs :ds_attributes, :ds_key
        external_ref_column_defs()
        column :type, :varchar, :size => 15 # instance | template | composite
        #TODO: is 'user" a well defined basic type?
        column :basic_type, :varchar, :size => 15 # service | package | language | application | client | feature | user ..
        column :only_one_per_node, :boolean, :default => true
        column :version, :varchar, :size => 25 # version of underlying component (not chef recipe .... version)
        column :uri, :varchar
        column :ui, :json
        #constraint_node_id is used when items in library to point to a node of type contraint or contraint-common-node
        #in library parent niode is used to link to image
        #in datacenter constraint_node_id will be null and if parent is a node it will have type instance or staged
        foreign_key :constraint_node_id, :node, FK_SET_NULL_OPT
        
        virtual_column :attributes, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :attribute,
           :join_type => :left_outer,
           :join_cond=>{:component_component_id => q(:component,:id)}, #TODO: want to use p(:component,:attribute) on left hand side
           :cols => [:id,:display_name,:component_component_id,:value_derived,:value_asserted,:semantic_type,:semantic_type_summary]
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

        virtual_column :containing_datacenter, :type => :varchar, :hidden => true,
          :remote_dependencies =>
         [
          {
            :model_name => :datacenter,
            :sequel_def => lambda{|ds|ds.join_table(:right_outer,:node__node,{:datacenter_datacenter_id => :datacenter__id}).select({:node__id => :node_id},:datacenter__display_name)},
            :join_type => :left_outer,
            :join_cond=>{:node_id => :component__node_node_id}
          },
          {
            :model_name => :datacenter,
            :sequel_def => lambda{|ds|ds.join_table(:right_outer,:node__node_group,{:datacenter_datacenter_id => :datacenter__id}).select({:node_group__id => :node_group_id},:datacenter__display_name)},
            :join_type => :left_outer,
            :join_cond=>{:node_group_id => :component__node_node_group_id}
          }
         ]


        virtual_column :parent_name, :possible_parents => [:component,:library,:node,:node_group]

        many_to_one :component, :library, :node, :node_group
        one_to_many :component, :attribute_link, :attribute, :monitoring_item
      end
    end
    ##### Actions
    ### virtual column defs
    
    def containing_datacenter()
      (self[:datacenter]||{})[:display_name]||(self[:datacenter2]||{})[:display_name]
    end

    #TODO: write as sql fn for efficiency
    def has_pending_change()
      ((self[:state_change]||{})[:count]||0) > 0 or ((self[:state_change2]||{})[:count]||0) > 0
    end
    #######################
    ### object procssing and access functions
    #object processing and access functions
    def self.add_model_specific_override_attrs!(override_attrs)
      override_attrs[:display_name] = SQL::ColRef.qualified_ref
    end

    ###### Helper fns


    def get_contained_attribute_ids(opts={})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      nested_cmps = get_objects(ModelHandle.new(id_handle[:c],:component),nil,:parent_id => parent_id)

      (get_directly_contained_object_ids(:attribute)||[]) +
      (nested_cmps||[]).map{|cmp|cmp.get_contained_attribute_ids(opts)}.flatten()
    end

    #type can be :asserted, :derived or :value
    def get_contained_attribute_values(type,opts={})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      nested_cmps = get_objects(ModelHandle.new(id_handle[:c],:component),nil,:parent_id => parent_id)

      ret = Hash.new
      (nested_cmps||[]).each do |cmp|
	values = cmp.get_contained_attribute_values(type,opts)
	if values
	  ret[:component] ||= Hash.new
          ret[:component][cmp.get_qualified_ref.to_sym] = values
        end
      end
      dir_vals = get_direct_attribute_values(type,opts)
      ret[:attribute] = dir_vals if dir_vals
      ret
    end

    def get_direct_attribute_values(type,opts={})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      attr_val_array = Model.get_objects(ModelHandle.new(c,:attribute),nil,:parent_id => parent_id)

      return nil if attr_val_array.nil?
      return nil if attr_val_array.empty?
      ret = {}
      attr_type = {:asserted => :value_asserted, :derived => :value_derived, :value => :attribute_value}[type]
      attr_val_array.each do |attr|
        v = {:value => attr[attr_type],:id => attr[:id]}
        opts[:attr_include].each{|a|v[a]=attr[a]} if opts[:attr_include]
        ret[attr.get_qualified_ref.to_sym] = v
      end
      ret
    end

    def get_objects_associated_nodes()
      assocs = Model.get_objects(ModelHandle.new(@c,:assoc_node_component),:component_id => self[:id])
      return Array.new if assocs.nil?
      assocs.map{|assoc|Model.get_object(IDHandle[:c=>@c,:guid => assoc[:node_id]])}
    end
  end
end

