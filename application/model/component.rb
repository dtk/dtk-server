module XYZ
  class Component < Model
    set_relation_name(:component,:component)
    class << self
      def up()
        ds_column_defs :ds_attributes, :ds_key
        external_ref_column_defs()
        column :component_type, :varchar #this will reflect whether component is apache, mysql etc and will enable display_name to be modified by user
        column :type, :varchar, :size => 15 # instance | composite
        #TODO: is 'user" a well defined basic type?
        column :basic_type, :varchar, :size => 15 # service | package | database_server | database | language | application | client | feature | user ..
        column :only_one_per_node, :boolean, :default => true
        column :version, :varchar, :size => 25 # version of underlying component (not chef recipe .... version)
        column :uri, :varchar
        column :ui, :json
        #:assembly_id (in contrast to parent field :component_id) is for tieing teh component to a composite component which is not a container
        foreign_key :assembly_id, :component, FK_SET_NULL_OPT
        column :view_def_ref, :varchar
        many_to_one :component, :library, :node, :node_group, :datacenter
        one_to_many :component, :attribute_link, :attribute, :monitoring_item, :constraints
        virtual_column :parent_name, :possible_parents => [:component,:library,:node,:node_group]

        virtual_column :view_def_key, :type => :varchar, :hidden => true, :local_dependencies => [:id,:view_def_ref,:component_type] 

        virtual_column :attributes, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :attribute,
           :join_type => :left_outer,
           :convert => true,
           :join_cond=>{:component_component_id => q(:component,:id)}, #TODO: want to use p(:component,:attribute) on left hand side
           :cols => [:id,:display_name,:component_component_id,:value_derived,:value_asserted,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change]
         }
        ]
        virtual_column :attributes_view_def_info, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :attribute,
           :join_type => :left_outer,
           :convert => true,
           :filter => [:and, [:eq, :hidden, false]],
           :join_cond=>{:component_component_id => q(:component,:id)}, #TODO: want to use p(:component,:attribute) on left hand side
           :cols => [:id,:display_name,:view_def_key,:component_component_id,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change]
         }
        ]

        virtual_column :constraints, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :constraints,
           :join_type => :left_outer,
           :convert => true,
           :join_cond=>{:component_component_id => q(:component,:id)}, 
           :cols => [:id,:display_name,id(:component),:node_constraints,:component_constraints]
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

        virtual_column :node_assembly_parts_with_attrs, :type => :json, :hidden => true,
        :remote_dependencies => 
          [
           node_assembly_parts,
           {
             :model_name => :attribute,
             :join_type => :left_outer,
             :join_cond=>{:node_node_id => q(:node,:id)},
             :cols => [:id,:display_name,:node_node_id,:value_asserted]
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
        set_submodel(:assembly)
      end
    end
    ##### Actions
    ### virtual column defs
    def view_def_key()
      self[:view_def_ref]||self[:component_type]||self[:id]
    end

    def containing_datacenter()
      (self[:datacenter_direct]||{})[:display_name]||
      (self[:datacenter_node]||{})[:display_name]||
        (self[:datacenter_node_group]||{})[:display_name]
    end

    #TODO: write as sql fn for efficiency
    def has_pending_change()
      ((self[:state_change]||{})[:count]||0) > 0 or ((self[:state_change2]||{})[:count]||0) > 0
    end

    #######################
    ######### Model apis
    def get_constraints()
      opts = {:ret_keys_as_symbols => false}
      get_objects_col_from_sp_hash({:columns => [:constraints]},:constraints,opts).first
    end

    def get_containing_node_id()
      return self[:node_node_id] if self[:node_node_id]
      row = get_objects_from_sp_hash(:columns => [:node_node_id,:containing_node_id_info]).first
      row[:node_node_id]||(row[:parent_component]||{})[:node_node_id]
    end

    ####################
    def save_view_in_cache?(type,user_context)
      ViewDefProcessor.save_view_in_cache?(:display,id_handle(),user_context)
    end

    def determine_cloned_components_parent(specified_target_idh)
      cmp_fs = FieldSet.opt([:id,:display_name,:component_type],:component)
      specified_target_id = specified_target_idh.get_id()
      cmp_ds = Model.get_objects_just_dataset(model_handle,{:id => id()},cmp_fs)
      mapping_ds = SQL::ArrayDataset.create(self.class.db,SubComponentComponentMapping,model_handle.createMH(:mapping))
                          
      first_join_ds =  cmp_ds.graph(:inner,mapping_ds,{:component => :component_type})

      parent_cmp_ds = Model.get_objects_just_dataset(model_handle,{:node_node_id => specified_target_idh.get_id()},cmp_fs)

      final_join_ds = first_join_ds.graph(:inner,parent_cmp_ds,{:component_type => :parent},{:convert => true})
      
      target_info = final_join_ds.all().first
      return specified_target_idh unless target_info
      target_info[:component2].id_handle()
    end

   private
    SubComponentComponentMapping = 
      [
       {:component => "postgresql__db", :parent => "postgresql__server"}
      ]
   public

    def clone_post_copy_hook(clone_copy_output,opts={})
      component_idh = clone_copy_output.id_handles.first
      add_needed_sap_attributes(component_idh)
      parent_action_id_handle = id_handle().get_top_container_id_handle(:datacenter)
      StateChange.create_pending_change_item(:new_item => component_idh, :parent => parent_action_id_handle)
    end

    def add_needed_sap_attributes(component_idh)
      sp_hash = {
        :filter => [:and, [:oneof, :basic_type, BasicTypeInfo.keys]],
        :columns => [:id, :display_name,:basic_type]
      }
      component = component_idh.get_objects_from_sp_hash(sp_hash).first
      return nil unless component
      
      basic_type_info = BasicTypeInfo[component[:basic_type]]
      sap_dep = basic_type_info[:sap_dependency]

      sap_info = component.get_objects_from_sp_hash(:columns => [:id, :display_name, sap_dep]).first
      unless sap_info
        Log.error("error in finding sap dependencies for component #{component_idh}")
        return nil
      end

      sap_config_attr = sap_info[:attribute]
      par_attr = sap_info[:parent_attribute]
      node = sap_info[:node]

      sap_val = basic_type_info[:fn].call(sap_config_attr[:attribute_value],par_attr[:attribute_value])
      sap_attr_row = Aux::hash_subset(basic_type_info,[{:sap => :ref},{:sap => :display_name},:description,:semantic_type,:semantic_type_summary])
      sap_attr_row.merge!(
         :component_component_id => component[:id],
         :value_derived => sap_val,
         :is_port => true,
         :hidden => true,
         :data_type => "json")

      attr_mh = component_idh.createMH(:model_name => :attribute, :parent_model_name => :component)
      sap_attr_idh = self.class.create_from_rows(attr_mh,[sap_attr_row], :convert => true).first

      return nil unless sap_attr_idh
      AttributeLink.create_links_sap(basic_type_info,sap_attr_idh,sap_config_attr.id_handle(),par_attr.id_handle(),node.id_handle())
    end
   private
    #TODO: some of these are redendant of whats in sap_dependency_X like "sap__l4" and "sap__db"
    BasicTypeInfo = {
      "database" => {
        :sap_dependency => :sap_dependency_database,
        :sap => "sap__db",
        :sap_config => "sap_config__db",
        :sap_config_fn_name => "sap_config_conn__db",
        :parent_attr => "sap__l4",
        :parent_fn_name => "sap_conn__l4__db",
        :semantic_type => {":array" => "sap__db"}, #TODO: need the  => {"application" => service qualification)
        :semantic_type_summary => "sap__db",
        :description => "DB access point",
        :fn => lambda{|sap_config,par|compute_sap_db(sap_config,par)}
      }
    }
   protected
    def self.compute_sap_db(sap_config_val,par_vals)
      #TODO: check if it is this simple; also may not need and propagate as byproduct of adding a link 
      par_vals.map{|par_val|sap_config_val.merge(par_val)}
    end
   public

    ### object processing and access functions
    def get_component_with_attributes_unraveled()
      sp_hash = {:columns => [:id,:display_name,:component_type,:basic_type,:attributes]}
      component_and_attrs = get_objects_from_sp_hash(sp_hash)
      return nil if component_and_attrs.empty?
      component = component_and_attrs.first.subset(:id,:display_name,:component_type,:basic_type)
      #if component_and_attrs.first[:attribute] null there shoudl only be one element in component_and_attrs
      return component.merge(:attributes => Array.new) unless component_and_attrs.first[:attribute]
      component.merge(:attributes => AttributeComplexType.flatten_attribute_list(component_and_attrs.map{|r|r[:attribute]}))
    end

    def get_info_for_view_def()
      sp_hash = {:columns => [:id,:display_name,:component_type,:basic_type,:attributes_view_def_info]}
      component_and_attrs = get_objects_from_sp_hash(sp_hash)
      return nil if component_and_attrs.empty?
      component = component_and_attrs.first.subset_with_vcs(:id,:display_name,:component_type,:basic_type,:view_def_key)
      #if component_and_attrs.first[:attribute] null there shoudl only be one element in component_and_attrs
      return component.merge(:attributes => Array.new) unless component_and_attrs.first[:attribute]
      opts = {:flatten_nil_value => true}
      component.merge(:attributes => AttributeComplexType.flatten_attribute_list(component_and_attrs.map{|r|r[:attribute]},opts))
    end

    def get_attributes_unraveled()
      sp_hash = {
        :filter => [:and, 
                    [:eq, :hidden, false]],
        :columns => [:id,:display_name,:attribute_value,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change]
      }
      raw_attributes = get_children_from_sp_hash(:attribute,sp_hash)
      flattened_attr_list = AttributeComplexType.flatten_attribute_list(raw_attributes)
      i18n = get_i18n_mappings_for_models(:attribute)
      flattened_attr_list.map do |a|
        name = a[:display_name]
        {
          :id => a[:unraveled_attribute_id],
          :name =>  name,
          :value => a[:attribute_value],
          :i18n => i18n_string(i18n,:attribute,name)
        }
      end
    end


    def add_model_specific_override_attrs!(override_attrs)
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

