require  File.expand_path('component/component_model_def_processor', File.dirname(__FILE__))
require  File.expand_path('component/component_view_meta_processor', File.dirname(__FILE__))
require  File.expand_path('component/component_template', File.dirname(__FILE__)) 

module XYZ
  class Component < Model
    include ComponentModelDefProcessor
    include ComponentViewMetaProcessor
    include ComponentTemplate
    set_relation_name(:component,:component)
    class << self
      def up()
        ds_column_defs :ds_attributes, :ds_key
        external_ref_column_defs()

        #columns related to name/labels
        #specfic labels of components and its attributes
        column :i18n_labels,  :json, :ret_keys_as_symbols => false

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
        column :extension_type, :varchar, :size => 30

        column :uri, :varchar
        column :ui, :json
        #:assembly_id (in contrast to parent field :component_id) is for tieing teh component to a composite component which is not a container
        foreign_key :assembly_id, :component, FK_SET_NULL_OPT
        column :view_def_ref, :varchar

        #TODO: change if multiple implementations per component
        foreign_key :implementation_id, :implementation, FK_SET_NULL_OPT

        #TODO: for efficiency materialize and if so have two variants of :component_parent for attribute; one for input, which brings in :connectivity_profile and other for output which deos not
        virtual_column :link_defs_external, :type => :json, :local_dependencies => [:component_type,:specific_type,:basic_type]
        virtual_column :connectivity_profile_internal, :type => :json, :local_dependencies => [:component_type,:specific_type,:basic_type]
        virtual_column :most_specific_type, :type => :varchar, :local_dependencies => [:specific_type,:basic_type]

        many_to_one :component, :library, :node, :node_group, :datacenter, :project
        one_to_many :component, :attribute_link, :attribute, :port_link, :monitoring_item, :dependency, :layout, :file_asset
        one_to_many_clone_omit :layout
        virtual_column :parent_name, :possible_parents => [:component,:library,:node,:node_group,:project]

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
           :cols => [:id,:display_name,id(:component),:port_is_external,:port_type,:has_port_object]
         )]
        ###### end of virtual columns related to attributes

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
    ##### Actions

    ### virtual column defs
    #TODO: expiremting with implementing this 'local def differently  
    def extended_base_id()
      if self[:extended_base] and self[:implementation_id]
        sp_hash = {
          :cols => [:id],
          :filter => [:and, [:eq, :implementation_id, self[:implementation_id]],
                      [:eq, :component_type, self[:extended_base]]]
        }
        ret = Model.get_objects_from_sp_hash(model_handle,sp_hash).first[:id]
      else
        base_sp_hash = {
          :cols => [:implementation_id,:extended_base]
        }
        join_array = 
          [{
             :model_name => :component,
             :alias => :base_component,
             :join_type => :inner,
             :join_cond => {:implementation_id => :component__implementation_id, :component_type => :component__extended_base},
             :cols => [:id,:implementation_id,:component_type]
         }]
        ret = Model.get_objects_from_join_array(model_handle,base_sp_hash,join_array).first[:base_component][:id]
      end
      self[:extended_base_id] = ret
    end

    def view_def_key()
      self[:view_def_ref]||self[:component_type]||self[:id]
    end

    def most_specific_type()
      self[:specific_type]||self[:basic_type]
    end

    def link_defs_external()
      LinkDefsExternal.find(self[:component_type])
    end
    def connectivity_profile_internal()
      LinkDefsInternal.find(self[:component_type])
    end
    
    def multiple_instance_ref()
      (self[:ref_num]||1) - 1 
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
    def get_implementation_file_paths()
      sp_hash = {:cols => [:id,:display_name,:implementation_file_paths]}
      unravelled_ret = get_objects_from_sp_hash(sp_hash)
      indexed_ret = Hash.new
      unravelled_ret.each do |r|
        unless implementation = indexed_ret[r[:implementation][:id]] 
          implementation = indexed_ret[r[:implementation][:id]] = r[:implementation].reject{|k,v|k == :project_id}.merge(:model_name => "implementation")
        end
        file_assets = implementation[:file_assets] ||= Array.new
        FileAsset.set_hierrachical_file_struct!(file_assets,r[:file_asset].reject{|k,v|k == :implementation_implementation_id}) if r[:file_asset]
      end
      indexed_ret.values
    end


    def add_config_file(file_name,file_content)
      #TODO: may check first that object does not have already a config file with same name
      parent_col = DB.parent_field(:component,:file_asset)

      create_row = {
        :ref => file_name,
        :type => "config_file",
        :file_name => file_name,
        :display_name => file_name,
        parent_col => id(),
        :content => file_content
      }

      file_asset_mh = id_handle().create_childMH(:file_asset)
      Model.create_from_rows(file_asset_mh,[create_row])
    end

    def get_config_file(file_name)
      sp_hash = {
        :model_name => :file_asset,
        :filter => [:and, [:eq, :file_name, file_name], [:eq, :type, "config_file"]],
        :cols => [:id,:content]
      }
      get_children_from_sp_hash(:file_asset,sp_hash).first
    end
    def get_config_files(opts={}) # opts: {:include_content => true} means include content, otherwise just ids and file names returned
      cols = [:id,:file_name]
      cols << :content if opts[:include_content]
      sp_hash = {
        :model_name => :file_asset,
        :filter => [:eq, :type, "config_file"],
        :cols => cols
      }
      get_children_from_sp_hash(:file_asset,sp_hash)
    end

    def get_virtual_attribute(attribute_name,cols,field_to_match=:display_name)
      sp_hash = {
        :model_name => :attribute,
        :filter => [:eq, field_to_match, attribute_name],
        :cols => cols
      }
      get_children_from_sp_hash(:attribute,sp_hash).first
    end
    
    def is_extension?()
      return false if self.kind_of?(Assembly)
      Log.error("this should not be called if :extended_base is not set") unless self.has_key?(:extended_base)
      self[:extended_base] ? true : false
    end

    #looks at 
    # 1) directly directly connected attributes
    # 2) if extension then attributes on teh extenion's base
    # 3) if base then extensions on all its attributes (TODO: NOTE: in which case multiple_instance_clause may be needed)
    def self.get_virtual_attributes__include_mixins(attrs_to_get,cols,field_to_match=:display_name)
      ret = Hash.new
      #TODO: may be able to avoid this loop
      attrs_to_get.each do |component_id,hash_value|
        attr_info = hash_value[:attribute_info]
        component = hash_value[:component]
        attr_names = attr_info.map{|a|a[:attribute_name].to_s}
        rows = component.get_virtual_attributes__include_mixins(attr_names,cols,field_to_match)
        rows.each do |attr|
          attr_name = attr[field_to_match]
          ret[component_id] ||= Hash.new
          ret[component_id][attr_name] = attr
        end
      end
      ret
    end

    def get_virtual_attributes__include_mixins(attribute_names,cols,field_to_match=:display_name,multiple_instance_clause=nil)
      is_extension?() ?
        get_virtual_attributes_aux_extension(attribute_names,cols,field_to_match,multiple_instance_clause) :
        get_virtual_attributes_aux_base(attribute_names,cols,field_to_match,multiple_instance_clause)
    end

    def self.get_components_related_by_mixins(components,cols)
      return Array.new if components.empty?
      sample_cmp = components.first
      component_mh = sample_cmp.model_handle()
      #use base cmp id as equivalence class and find all members of equivalence class to find what each related component is
      #associated with
      cmp_id_to_equiv_class = Hash.new
      equiv_class_members = Hash.new
      ext_cmps = Array.new
      base_cmp_info = Array.new
      components.each do |cmp|
        id = cmp[:id]
        if cmp[:extended_base]
          raise Error.new("cmp[:implementation_id] must be set") unless cmp[:implementation_id]
          ext_cmps << cmp
          extended_base_id = cmp[:extended_base_id]
          base_cmp_info << {:id => extended_base_id, :extended_base => cmp[:extended_base], :implementation_id => cmp[:implementation_id]}
          cmp_id_to_equiv_class[id] = (equiv_class_members[extended_base_id] ||= Array.new) << id
        else
          base_cmp_info << {:id => cmp[:id]}
          cmp_id_to_equiv_class[id] = (equiv_class_members[id] ||= Array.new) << id
        end
      end

      indexed_ret = Hash.new
      get_components_related_by_mixins_from_extension(component_mh,ext_cmps,cols).each do |found_base_cmp|
        id = found_base_cmp[:id]
        #if found_base_cmp in components dont put in result
        unless cmp_id_to_equiv_class[id]
          indexed_ret[id] = found_base_cmp.merge(:assoc_component_ids => equiv_class_members[id])
        end
      end

      get_components_related_by_mixins_from_base(component_mh,base_cmp_info,cols).each do |found_ext_cmp|
        id = found_ext_cmp[:id]
        #if found_ext_cmp in components dont put in result
        unless cmp_id_to_equiv_class[id]
          indexed_ret[id] = found_ext_cmp.merge(:assoc_component_ids => equiv_class_members[found_ext_cmp[:extended_base_id]])
        end
      end
      indexed_ret.values
    end

  private
    def self.get_components_related_by_mixins_from_extension(component_mh,extension_cmps,cols)
      return Array.new if extension_cmps.empty?
      base_ids = extension_cmps.map{|cmp|cmp[:extended_base_id]}
      sp_hash = {
        :model_name => :component,
        :filter => [:oneof, :id, base_ids],
        :cols => Aux.array_add?(cols,[:id])
      }
      get_objects_from_sp_hash(component_mh,sp_hash)
    end

    def self.get_components_related_by_mixins_from_base(component_mh,base_cmp_info,cols)
      return Array.new if base_cmp_info.empty?
      filter = 
        if base_cmp_info.size == 1
          extended_base_id_filter(base_cmp_info.first)
        else
          [:or] + base_cmp_info.map{|item|extended_base_id_filter(item)}
        end
      sp_hash = {
        :model_name => :component,
        :filter => filter,
        :cols => Aux.array_add?(cols,[:id])
      }
      get_objects_from_sp_hash(component_mh,sp_hash)
    end

    def extended_base_id_filter(base_cmp_info_item)
      [:and,[:eq, :implementation_id, base_cmp_info_item[:implementation_id]],
       [:eq,:extended_base, base_cmp_info_item[:extended_base]]]
    end


    def get_virtual_attributes_aux_extension(attribute_names,cols,field_to_match=:display_name,multiple_instance_clause=nil)
      component_id = self[:id]
      base_id = self[:extended_base_id]
      sp_hash = {
        :model_name => :attribute,
        :filter => [:and, [:oneof, field_to_match, attribute_names], [:oneof, :component_component_id, [component_id,base_id]]],
        :cols => Aux.array_add?(cols,[:component_component_id,field_to_match])
      }
      attr_mh = model_handle().createMH(:attribute)
      Model.get_objects_from_sp_hash(attr_mh,sp_hash)
    end

    def get_virtual_attributes_aux_base(attribute_names,cols,field_to_match=:display_name,multiple_instance_clause=nil)
      raise Error.new("Should not be called unless :component_type and :implementation_id are set") unless self[:component_type] and self[:implementation_id]
      component_id = self[:id]
      base_sp_hash = {
        :model_name => :component,
        :filter => [:and, [:eq,:implementation_id, self[:implementation_id]],
                    [:or, [:eq, :extended_base, self[:component_type]],[:eq, :id, self[:id]]]],
        :cols => [:id,:extended_base,:implementation_id]
      }
      join_array = 
        [{
           :model_name => :attribute,
           :convert => true,
           :join_type => :inner,
           :filter => [:oneof, field_to_match, attribute_names],
           :join_cond => {:component_component_id => :component__id},
           :cols => Aux.array_add?(cols,[:component_component_id,field_to_match])
         }]
      Model.get_objects_from_join_array(model_handle,base_sp_hash,join_array).map{|r|r[:attribute]}
    end

   public

    def get_attributes_ports()
      opts = {:keep_ref_cols => true}
      rows = get_objects_from_sp_hash({:columns => [:ref,:ref_num,:attributes_ports]},opts)
      return Array.new if rows.empty?
      component_ref = rows.first[:ref]
      component_ref_num = rows.first[:ref_num]
      rows.map do |r|
        r[:attribute].merge(:component_ref => component_ref,:component_ref_num => component_ref_num) if r[:attribute]
      end.compact
    end

    def get_component_i18n_label()
      ret = get_stored_component_i18n_label?()
      return ret if ret
      i18n = get_i18n_mappings_for_models(:component)      
      i18n_string(i18n,:component,self[:display_name])
    end

    def get_attribute_i18n_label(attribute)
      ret = get_stored_attribute_i18n_label?(attribute)
      return ret if ret
      i18n = get_i18n_mappings_for_models(:attribute,:component)      
      i18n_string(i18n,:attribute,attribute[:display_name],self[:component_type])
    end

    def update_component_i18n_label(label)
      update_hash = {:id => self[:id], :i18n_labels => {i18n_language() => {"component" => label}}}
      Model.update_from_rows(model_handle,[update_hash],:partial_value=>true)
    end
    def update_attribute_i18n_label(attribute_name,label)
      update_hash = {:id => self[:id], :i18n_labels => {i18n_language() => {"attributes" => {attribute_name => label}}}}
      Model.update_from_rows(model_handle,[update_hash],:partial_value=>true)
    end

    #self is an instance and it finds a library component
    #multiple_instance_clause is used in case multiple extensions of same type and need to select particular one
    #TODO: extend with logic for multiple_instance_clause
    def get_extension_in_library(extension_type,cols=[:id,:display_name],multiple_instance_clause=nil)
      base_sp_hash = {
        :model_name => :implementation,
        :filter => [:eq, :id, self[:implementation_id]],
        :cols => [:id,:ancestor_id]
      }
      join_array = 
        [
         {          
           :model_name => :component,
           :alias => :library_template,
           :join_type => :inner,
           :filter => [:eq, :extension_type, extension_type.to_s],
           :convert => true,
           :join_cond => {:implementation_id => :implementation__ancestor_id},
           :cols => Aux.array_add?(cols,:implementation_id)
         }
        ]
      rows = Model.get_objects_from_join_array(model_handle(:implementation),base_sp_hash,join_array)
      Log.error("get extension library shoudl only match one component") if rows.size > 1
      rows.first && rows.first[:library_template]
    end

   private
    def get_stored_attribute_i18n_label?(attribute)
      return nil unless self[:i18n_labels]
      ((self[:i18n_labels][i18n_language()]||{})["attributes"]||{})[attribute[:display_name]]
    end
    def get_stored_component_i18n_label?()
      return nil unless self[:i18n_labels]
      ((self[:i18n_labels][i18n_language()]||{})["component"]||{})[self[:display_name]]
    end
   public

    def get_constraints!(opts={})
      #TODO: may see if precalculating more is more efficient
      cmp_cols = [:only_one_per_node,:component_type,:extended_base,:implementation_id]
      rows = get_objects_from_sp_hash(:cols => [:dependencies] + cmp_cols)
      cmp_info = rows.first #just picking first since component info same for all rows
      cmp_cols.each{|col|self[col] = cmp_info[col]} if opts[:update_object]

      constraints = rows.map{|r|Constraint.create(r[:dependencies]) if r[:dependencies]}.compact
      constraints << Constraint::Macro.only_one_per_node(cmp_info[:component_type]) if cmp_info[:only_one_per_node]
      if cmp_info[:extended_base]
        sp_hash = {:cols => [:id], :filter => [:eq, :ancestor_id, cmp_info[:implementation_id]]}
        library_impl = Model.get_objects_from_sp_hash(model_handle(:implementation),sp_hash).first
        constraints << Constraint::Macro.base_for_extension(cmp_info[:extended_base],library_impl[:id])
      end
      return Constraints.new() if constraints.empty?
      Constraints.new(:and,constraints)
    end

    def get_containing_node_id()
      return self[:node_node_id] if self[:node_node_id]
      row = get_objects_from_sp_hash(:columns => [:node_node_id,:containing_node_id_info]).first
      row[:node_node_id]||(row[:parent_component]||{})[:node_node_id]
    end

    ####################
    def save_view_in_cache?(type,user_context)
      ViewDefProcessor.save_view_in_cache?(type,id_handle(),user_context)
    end

    def determine_cloned_components_parent(specified_target_idh)
      #TODO: may deprecate if not using; previously mapped extensions to parents; now putting them with node as tehir parent
      return specified_target_idh if SubComponentComponentMapping.empty?
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
#       {:component => "postgresql__db", :parent => "postgresql__server"}
      ]
   public

    ######## clone related ##############################
    def clone_post_copy_hook(clone_copy_output,opts={})
      component_idh = clone_copy_output.id_handles.first
      add_needed_sap_attributes(component_idh)
      parent_action_id_handle = id_handle().get_top_container_id_handle(:datacenter)
      StateChange.create_pending_change_item(:new_item => component_idh, :parent => parent_action_id_handle)
    end

    #handles copying over if needed component template and implementation into project
    def clone_post_copy_hook_into_node(node)
      #processing so that component's implementation and template are cloned to project
      #self will have implementation_id set to library implementation and ancestor_id set to library template
      #need to search project to see if has implementation that matches (same repo)
      #if match then set new_cmps impelemntation_id to this otehrwise need to clone implementaion in library to project
      proj = node.get_project()
      proj_idh = proj.id_handle()

      #create new project implementation if needed
      library_impl = id_handle(:model_name => :implementation,:id => self[:implementation_id]).create_object()
      new_impl_id = library_impl.clone_into_project_if_needed(proj).get_id()

      #find new ancestor_id
      library_cmp_tmpl_idh = id_handle(:id => self[:ancestor_id])
      #ok to do below because self and library_cmp_tmpl share attribute values
      library_cmp_tmpl =  library_cmp_tmpl_idh.create_object
      proj_cmp_tmpl_idh = find_match_in_project(proj_idh)
      new_ancestor_id = proj_cmp_tmpl_idh ? proj_cmp_tmpl_idh.get_id() : proj.clone_into(library_cmp_tmpl,{:implementation_id => new_impl_id,:extended_base => self[:extended_base]})

      update_from_hash_assignments(:implementation_id => new_impl_id, :ancestor_id => new_ancestor_id)
    end
   private
    def find_match_in_project(project_idh)
      sp_hash = {
        :filter => [:and,
                    [:eq, :project_project_id, project_idh.get_id()],
                    [:eq, :component_type, self[:component_type]],
                    [:eq,:version, self[:version]]
                   ],
        :cols => [:id]
      }
      row = Model.get_objects_from_sp_hash(model_handle,sp_hash).first
      row && row.id_handle()
    end
   public

    def source_clone_info_opts()
      {:ret_new_obj_with_cols => [:id,:implementation_id,:component_type,:version,:ancestor_id]}
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

    ######## end of clone related ##############################

   public
    ### object processing and access functions
    def get_component_with_attributes_unraveled(attr_filters={:hidden => true})
      sp_hash = {:columns => [:id,:display_name,:component_type,:basic_type,:attributes,:i18n_labels]}
      component_and_attrs = get_objects_from_sp_hash(sp_hash)
      return nil if component_and_attrs.empty?
      component = component_and_attrs.first.subset(:id,:display_name,:component_type,:basic_type,:i18n_labels)
      component_attrs = {:component_type => component[:component_type],:component_name => component[:display_name]}
      filtered_attrs = component_and_attrs.map do |r|
        attr = r[:attribute]
        attr.merge(component_attrs) if attr and not attribute_is_filtered?(attr,attr_filters)
      end.compact
      attributes = AttributeComplexType.flatten_attribute_list(filtered_attrs)
      component.merge(:attributes => attributes)
    end
   private
    #only filters if value is known
    def attribute_is_filtered?(attribute,attr_filters)
      return false if attr_filters.empty?
      attr_filters.each{|k,v|return true if attribute[k] == v}
      false
    end

   public

    def get_view_meta(view_type,virtual_model_ref)
      from_db = get_instance_layout_from_db(view_type)
      virtual_model_ref.set_view_meta_info(from_db[:id],from_db[:updated_at]) if from_db

      layout_def = (from_db||{})[:def] || Layout.create_def_from_field_def(get_field_def(),view_type)
      create_view_meta_from_layout_def(view_type,layout_def)
    end

    def get_view_meta_info(view_type)
      #TODO: can be more efficient (rather than using get_instance_layout_from_db can use something that returns most recent laypout id); also not sure whether if no db hit to return id()
      from_db = get_instance_layout_from_db(view_type)
      return [from_db[:id],from_db[:updated_at]] if from_db
      [id(),Time.new()]
    end

    def get_layouts(view_type)
      from_db = get_layouts_from_db(view_type)
      return from_db unless from_db.empty?
      Layout.create_and_save_from_field_def(id_handle(),get_field_def(),view_type)
      get_layouts_from_db(view_type)
    end

    def add_layout(layout_info)
      Layout.save(id_handle(),layout_info)
    end

   protected
    def get_layouts_from_db(view_type,layout_vc=:layouts)
      unprocessed_rows = get_objects_col_from_sp_hash({:columns => [layout_vc]},:layout)
      #TODO: more efficient would be to use db sort
      unprocessed_rows.select{|l|l[:type] == view_type.to_s}.sort{|a,b|b[:updated_at] <=> a[:updated_at]}
    end

    def get_instance_layout_from_db(view_type)
      #TODO: more efficient would be to use db limit 
      instance_layout = get_layouts_from_db(view_type,:layouts).first
      return instance_layout if instance_layout
      instance_layout = get_layouts_from_db(view_type,:layouts_from_ancestor).first
      return instance_layout if instance_layout
    end
   public

    #TODO: wil be deperacted
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

    def get_attributes_unraveled(to_set={},opts={})
      sp_hash = {
        :filter => [:and, 
                    [:eq, :hidden, false]],
        :columns => [:id,:display_name,:component_component_id,:attribute_value,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change,:port_type,:read_only]
      }
      raw_attributes = get_children_from_sp_hash(:attribute,sp_hash)
      return Array.new if raw_attributes.empty?
      if to_set.has_key?(:component_id)
        sample = raw_attributes.first
        to_set[:component_id] = sample[:component_component_id]
      end

      flattened_attr_list = AttributeComplexType.flatten_attribute_list(raw_attributes,opts)
      i18n = get_i18n_mappings_for_models(:attribute)
      flattened_attr_list.map do |a|
        unless a[:hidden]
          name = a[:display_name]
          {
            :id => a[:unraveled_attribute_id],
            :name =>  name,
            :value => a[:attribute_value],
            :i18n => i18n_string(i18n,:attribute,name),
            :is_readonly => a.is_readonly?
          }
        end
      end.compact
    end

    def get_virtual_object_attributes(opts={})
      to_set = {:component_id => nil}
      attrs = get_attributes_unraveled(to_set)
      vals = attrs.inject({:id=>to_set[:component_id]}){|h,a|h.merge(a[:name].to_sym => a[:value])}
      if opts[:ret_ids]
        ids = attrs.inject({}){|h,a|h.merge(a[:name].to_sym => a[:id])}
        return [vals,ids]
      end
      vals
    end

    def add_model_specific_override_attrs!(override_attrs,target_obj)
      override_attrs[:display_name] ||= SQL::ColRef.qualified_ref 
      override_attrs[:type] ||= (target_obj.model_handle[:model_name] == :node ? "instance" : "template")
      override_attrs[:updated] ||= false
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

    def is_assembly?()
      self[:type] == "composite"
    end
    def is_base_component?()
      not self[:type] == "composite"
    end
  end
end

