files =
  [
   'model_def_processor', 
   'view_meta_processor', 
   'template',  
   'clone',
   'user',  
   'meta'
  ]
r8_nested_require('component',files)

module XYZ
  class Component < Model
    include ComponentModelDefProcessor
    include ComponentViewMetaProcessor
    include ComponentTemplate
    include ComponentClone
    extend ComponentUserClassMixin
    set_relation_name(:component,:component)
    extend ComponentMetaClassMixin 
    class << self
    end

    def self.common_columns()
      [
       :id,
       :display_name,
       :name,
       :basic_type,
       :type, 
       :component_type,
       :specific_type,
       :extended_base,
       :extension_type,
       :description,
       :implementation_id,
       :only_one_per_node,
       :assembly_id,
       :version,
       :config_agent_type,
       :ancestor_id,
       :library_id,
       :node_id,
       :project_id,
       :ui
      ]
    end
    #TODO: need to maintain relationship fro maintainability
    def self.common_real_columns()
      [
       :id,
       :display_name,
       :extension_type,
       :specific_type,
       :type,
       :component_type,
       :ancestor_id,
       :extended_base,
       :implementation_id,
       :assembly_id,
       :ui,
       :basic_type,
       :only_one_per_node,
       :version,
       :external_ref,
       :node_node_id,
       :project_project_id,
       :library_library_id
      ]
    end

    ### virtual column defs
    def name()
      self[:display_name]
    end
    def node_id()
      self[:node_node_id]
    end
    def project_id()
      self[:project_project_id]
    end
    def library_id()
      self[:library_library_id]
    end
    def config_agent_type()
      cmp_external_ref_type = (self[:external_ref]||{})[:type]
      case cmp_external_ref_type
       when "chef_recipe" then "chef"
       when "puppet_class","puppet_definition" then "puppet"
      end
    end

    def instance_extended_base_id()
      extended_base_id(:is_instance => true)
    end
    #TODO: expiremting with implementing this 'local def differently  
    def extended_base_id(opts={})
      if self[:extended_base] and self[:implementation_id] and (self[:node_node_id] or not opts[:is_instance]) 
        sp_hash = {
          :cols => [:id],
          :filter => [:and, [:eq, :implementation_id, self[:implementation_id]],
                      [:eq, :node_node_id, self[:node_node_id]],
                      [:eq, :component_type, self[:extended_base]]]
        }
        ret = Model.get_objects_from_sp_hash(model_handle,sp_hash).first[:id]
      else
        base_sp_hash = {
          :model_name => :component,
          :cols => [:implementation_id,:extended_base,:node_node_id]
        }
        join_array = 
          [{
             :model_name => :component,
             :alias => :base_component,
             :join_type => :inner,
             :join_cond => {
               :implementation_id => :component__implementation_id, 
               :component_node_node_id => :component__node_node_id,
               :component_type => :component__extended_base},
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
      LinkDefsExternal.find!(self)
    end
    def connectivity_profile_internal()
      (self[:link_defs]||{})["internal"] || LinkDefsInternal.find(self[:component_type])
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
      Model.create_from_row(file_asset_mh,create_row)
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

    def self.clear_dynamic_attributes_and_their_dependents(cmp_idhs)
      dynamic_attrs = get_objs_in_set(cmp_idhs,{:cols => [:dynamic_attributes]}).map{|r|r[:attribute]}
      Attribute.clear_dynamic_attributes_and_their_dependents(dynamic_attrs)
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

    def self.get_component_instances_related_by_mixins(components,cols)
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
          base_cmp_info << {:id => extended_base_id, :node_node_id => cmp[:node_node_id], :extended_base => cmp[:extended_base], :implementation_id => cmp[:implementation_id]}
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
    def sub_item_model_names()
      [:node,:component]
    end

    def self.get_components_related_by_mixins_from_extension(component_mh,extension_cmps,cols)
      return Array.new if extension_cmps.empty?
      base_ids = extension_cmps.map{|cmp|cmp[:instance_extended_base_id]}
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

    def self.extended_base_id_filter(base_cmp_info_item)
      if base_cmp_info_item[:extended_base] 
        [:and,[:eq, :implementation_id, base_cmp_info_item[:implementation_id]],
         [:eq,:node_node_id,base_cmp_info_item[:node_node_id]],
         [:eq,:extended_base, base_cmp_info_item[:extended_base]]]  
      else
      [:eq, :id, base_cmp_info_item[:id]]
      end
    end

    def get_virtual_attributes_aux_extension(attribute_names,cols,field_to_match=:display_name,multiple_instance_clause=nil)
      component_id = self[:id]
      base_id = self[:extended_base_id]
      sp_hash = {
        :model_name => :attribute,
        :filter => [:and, 
                    [:oneof, field_to_match, attribute_names], 
                    [:oneof, :component_component_id, [component_id,base_id]]],
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
        :filter => [:and, 
                    [:eq, :node_node_id, self[:node_node_id]], 
                    [:eq, :implementation_id, self[:implementation_id]],
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
      rows = get_objs(:cols => [:dependencies] + cmp_cols)
      cmp_info = rows.first #just picking first since component info same for all rows
      cmp_cols.each{|col|self[col] = cmp_info[col]} if opts[:update_object]

      constraints = rows.map{|r|Constraint.create(r[:dependencies]) if r[:dependencies]}.compact
      constraints << Constraint::Macro.only_one_per_node(cmp_info[:component_type]) if cmp_info[:only_one_per_node]
      constraints << Constraint::Macro.base_for_extension(cmp_info) if cmp_info[:extended_base]

      return Constraints.new() if constraints.empty?
      Constraints.new(:and,constraints)
    end

    #this provides for each component, what other components it depends on
    def self.get_component_type_and_dependencies(id_handles)
      ret = id_handles.inject({}) do |h,idh|
        h.merge(idh.get_id() => {:component_dependencies => Array.new})
      end

      sample_idh = id_handles.first
      sp_hash = {
        :cols => [:id,:dependencies, :extended_base, :component_type],
        :filter => [:oneof, :id, ret.keys]
      }
      rows = get_objs(sample_idh.createMH,sp_hash)
      rows.each do |r|
        id = r[:id]
        ret[id][:component_type] = r[:component_type]
        if r[:extended_base]
          ret[id][:component_dependencies] << r[:extended_base]
        elsif deps = r[:dependencies]
          #process dependencies
          #TODO: hack until we haev macros which will stamp the dependency to make this easier to detect
          #looking for signature where dependency has
          #:search_pattern=>{:filter=>[:and, [:eq, :component_type, <component_type>]
          filter = (deps[:search_pattern]||{})[":filter".to_sym]
          if filter and deps[:type] == "component"
            if filter[0] == ":eq" and filter[1] == ":component_type"
              ret[id][:component_dependencies] << filter[2]
            end
          end
        end
      end
      ret
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
      #TODO: taking out below to accomidate fact that using ref to qialify whether chef or puppet
      #TODO: think want to add way for components that can have many attributes to have this based on value of the 
      #attribut ethat serves as the key
      #override_attrs[:display_name] ||= SQL::ColRef.qualified_ref 
      into_node = (target_obj.model_handle[:model_name] == :node)
      override_attrs[:type] ||= (into_node ? "instance" : "template")
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

    def get_obj_with_common_cols()
      common_cols =  self.class.common_columns()
      ret = get_objs(:cols => common_cols).first
      ret.materialize!(common_cols)
    end

  end
end

