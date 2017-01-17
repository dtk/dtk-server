#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
%w(model_def_processor view_meta_processor clone user meta).each { |file| require_relative("component/#{file}") }
require_relative('branch_names')
module DTK
  class Component < Model
    require_relative('component/get_method')
    require_relative('component/template')
    require_relative('component/instance')
    require_relative('component/dependency')
    require_relative('component/test')
    require_relative('component/resource_matching')
    require_relative('component/include_module')
    require_relative('component/name')
    require_relative('component/domain')
    include GetMethod::Mixin
    extend GetMethod::ClassMixin
    include Dependency::Mixin
    extend Dependency::ClassMixin
    include TemplateMixin
    include ComponentModelDefProcessor
    include ComponentViewMetaProcessor
    include ComponentClone
    extend ComponentUserClassMixin
    extend ComponentMetaClassMixin
    extend BranchNames::ClassMixin
    include BranchNames::Mixin
    extend Name::ClassMixin
    include Name::Mixin

    set_relation_name(:component, :component)
    def self.common_columns
      [
       :id,
       :group_id,
       :display_name,
       :name,
       :external_ref,
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

    # context can have keys
    #  :assembly_id
    #  :allow_external_component (Boolean)
    def self.check_valid_id(model_handle, id, context = {})
      filter = add_assembly_id_clause?([:eq, :id, id], context)
      check_valid_id_helper(model_handle, id, filter)
    end

    # The method name_to_id is just used for component instances;
    # The possible forms for name are
    #   node/component_name
    #   node/module_name::component_name
    #   component_name
    #   module_name::component_name
    # the later two are for assemble wide components
    #
    # context can have keys
    #  :assembly_id
    #  :allow_external_component (Boolean)
    def self.name_to_id(model_handle, name, context = {})
      if context.empty?
        return name_to_id_default(model_handle, name)
      end

      assembly_id              = context[:assembly_id]
      allow_external_component = context[:allow_external_component]

      display_name = Component.display_name_from_user_friendly_name(name)
      # setting node_prefix to true, but node_name can be nil, meaning an assembly-wide component instance
      node_name, cmp_type, cmp_title = ComponentTitle.parse_component_display_name(display_name, node_prefix: true)

      sp_hash = {
        cols:   [:id, :node, :assembly_id],
        filter: add_assembly_id_clause?(Component::Instance.filter(cmp_type, cmp_title), context)
      }
      
      rows = get_objs(model_handle, sp_hash).select do |r|
        r[:node][:display_name] == node_name or r[:node].is_assembly_wide_node?
      end

      if context[:filter_by_node] && node_name
        rows.reject!{|cmp| cmp[:node][:display_name] != node_name}
      end
      
      case rows.size
      when 1
        rows.first[:id]
      when 0
        fail ErrorNameDoesNotExist.new(name, pp_object_type())
      else # rows.size > 1
        # if allow_external_component, favor a component instance in the service instance 
        if allow_external_component and assembly_id
          internal_to_assembly = rows.select { |r| r[:assembly_id] == assembly_id }
          if internal_to_assembly.size == 1
            return internal_to_assembly.first[:id]
          end
        end
        fail ErrorNameAmbiguous.new(name, rows.map { |r| r[:id] }, pp_object_type())
      end
    end

    # context can have keys
    #  :assembly_id
    #  :allow_external_component (Boolean)
    def self.add_assembly_id_clause?(base_filter, context = {})
      ret = base_filter
      if assembly_id = context[:assembly_id]
        unless context[:allow_external_component ]
          ret = [:and, ret, [:eq, :assembly_id, assembly_id]]
        end
      end
      ret
    end
    private_class_method :add_assembly_id_clause?

    def get_node
      get_obj_helper(:node)
    end

    def self.pending_changes_cols
      [:id, :node_for_state_change_info, :display_name, :basic_type, :external_ref, :node_node_id, :only_one_per_node, :extended_base_id, :implementation_id, :group_id]
    end

    # TODO: need to maintain relationship fro maintainability
    def self.common_real_columns
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

    def copy_as_assembly_template
      ret = id_handle().create_object(model_name: :assembly_template)
      each { |k, v| ret[k] = v }
      ret
    end

    def copy_as_assembly_instance
      ret = id_handle().create_object(model_name: :assembly_instance)
      each { |k, v| ret[k] = v }
      ret
    end

    # MOD_RESTRUCT: TODO: see if this is what is wanted; now returning what is used in implementation and module branch fields
    def self.default_version
      version_field_default()
    end

    ### display name functions

    ### end: display name functions

    ### virtual column defs
    def name
      self[:display_name]
    end

    def node_id
      self[:node_node_id]
    end

    def project_id
      self[:project_project_id]
    end

    def library_id
      self[:library_library_id]
    end

    # TODO: DTK-2805; deprecate use of external_ref and move from conceptthat there is a single config_agent_type,
    # rather there is type per action
    def config_agent_type
      external_ref = self[:external_ref] || {}
      return 'dynamic' if external_ref[:provider] == 'dynamic'
      case external_ref[:type]
       when 'chef_recipe' then 'chef'
       when 'puppet_class', 'puppet_definition' then 'puppet'
       when 'bash_command' then 'bash_commands'
       when 'ruby_function' then 'ruby_function'
       when 'docker' then 'docker'
       else 'no_op'
      end
    end

    def instance_extended_base_id
      extended_base_id(is_instance: true)
    end
    # TODO: expiremting with implementing this 'local def differently
    def extended_base_id(opts = {})
      if self[:extended_base] && self[:implementation_id] && (self[:node_node_id] or not opts[:is_instance])
        sp_hash = {
          cols: [:id],
          filter: [:and, [:eq, :implementation_id, self[:implementation_id]],
                   [:eq, :node_node_id, self[:node_node_id]],
                   [:eq, :component_type, self[:extended_base]]]
        }
        ret = Model.get_objects_from_sp_hash(model_handle, sp_hash).first[:id]
      else
        base_sp_hash = {
          model_name: :component,
          cols: [:implementation_id, :extended_base, :node_node_id]
        }
        join_array =
          [{
             model_name: :component,
             alias: :base_component,
             join_type: :inner,
             join_cond: {
               implementation_id: :component__implementation_id,
               component_node_node_id: :component__node_node_id,
               component_type: :component__extended_base },
             cols: [:id, :implementation_id, :component_type]
         }]
        ret = Model.get_objects_from_join_array(model_handle, base_sp_hash, join_array).first[:base_component][:id]
      end
      self[:extended_base_id] = ret
    end

    def view_def_key
      self[:view_def_ref] || self[:component_type] || self[:id]
    end

    def most_specific_type
      self[:specific_type] || self[:basic_type]
    end

    def link_defs_external
      LinkDefsExternal.find!(self)
    end

    def connectivity_profile_internal
      (self[:link_defs] || {})['internal'] || LinkDefsInternal.find(self[:component_type])
    end

    def multiple_instance_ref
      (self[:ref_num] || 1) - 1
    end

    def containing_datacenter
      (self[:datacenter_direct] || {})[:display_name] || (self[:datacenter_node] || {})[:display_name] || (self[:datacenter_node_group] || {})[:display_name]
     end

    # TODO: write as sql fn for efficiency
    def has_pending_change
      ((self[:state_change] || {})[:count] || 0) > 0 || ((self[:state_change2] || {})[:count] || 0) > 0
    end

    #######################
    ######### Model apis

    def add_config_file(file_name, file_content)
      # TODO: may check first that object does not have already a config file with same name
      parent_col = DB.parent_field(:component, :file_asset)

      create_row = {
        :ref => file_name,
        :type => 'config_file',
        :file_name => file_name,
        :display_name => file_name,
        parent_col => id(),
        :content => file_content
      }

      file_asset_mh = id_handle().create_childMH(:file_asset)
      Model.create_from_row(file_asset_mh, create_row)
    end

    def get_augmented_link_defs
      ndx_ret = {}
      get_objs(cols: [:link_def_links]).each do |r|
        link_def =  r[:link_def]
        pntr = ndx_ret[link_def[:id]] ||= link_def.merge(link_def_links: [])
        pntr[:link_def_links] << r[:link_def_link]
      end
      ret =  ndx_ret.values()
      ret.each { |r| r[:link_def_links].sort! { |a, b| a[:position] <=> b[:position] } }
      ret
    end

    def get_config_file(file_name)
      sp_hash = {
        model_name: :file_asset,
        filter: [:and, [:eq, :file_name, file_name], [:eq, :type, 'config_file']],
        cols: [:id, :content]
      }
      get_children_from_sp_hash(:file_asset, sp_hash).first
    end

    def get_config_files(opts = {}) # opts: {:include_content => true} means include content, otherwise just ids and file names returned
      cols = [:id, :file_name]
      cols << :content if opts[:include_content]
      sp_hash = {
        model_name: :file_asset,
        filter: [:eq, :type, 'config_file'],
        cols: cols
      }
      get_children_from_sp_hash(:file_asset, sp_hash)
    end

    def self.clear_dynamic_attributes_and_their_dependents(cmp_idhs)
      dynamic_attrs = get_objs_in_set(cmp_idhs, cols: [:dynamic_attributes]).map { |r| r[:attribute] }
      Attribute.clear_dynamic_attributes_and_their_dependents(dynamic_attrs)
    end

    def get_virtual_attribute(attribute_name, cols, field_to_match = :display_name)
      sp_hash = {
        model_name: :attribute,
        filter: [:eq, field_to_match, attribute_name],
        cols: cols
      }
      get_children_from_sp_hash(:attribute, sp_hash).first
    end

    def is_extension?
      return false if self.is_a?(Assembly)
      Log.error('this should not be called if :extended_base is not set') unless self.key?(:extended_base)
      self[:extended_base] ? true : false
    end

    # looks at
    # 1) directly directly connected attributes
    # 2) if extension then attributes on teh extenion's base
    # 3) if base then extensions on all its attributes (TODO: NOTE: in which case multiple_instance_clause may be needed)
    def self.get_virtual_attributes__include_mixins(attrs_to_get, cols, field_to_match = :display_name)
      ret = {}
      # TODO: may be able to avoid this loop
      attrs_to_get.each do |component_id, hash_value|
        attr_info = hash_value[:attribute_info]
        component = hash_value[:component]
        attr_names = attr_info.map { |a| a[:attribute_name].to_s }
        rows = component.get_virtual_attributes__include_mixins(attr_names, cols, field_to_match)
        rows.each do |attr|
          attr_name = attr[field_to_match]
          ret[component_id] ||= {}
          ret[component_id][attr_name] = attr
        end
      end
      ret
    end

    def get_virtual_attributes__include_mixins(attribute_names, cols, field_to_match = :display_name, multiple_instance_clause = nil)
      is_extension?() ?
        get_virtual_attributes_aux_extension(attribute_names, cols, field_to_match, multiple_instance_clause) :
        get_virtual_attributes_aux_base(attribute_names, cols, field_to_match, multiple_instance_clause)
    end

    def self.ret_component_with_namespace_for_node(cmp_mh, cmp_name, node_id, namespace, assembly)
      ret_cmp = nil
      match_cmps = []
      display_name = display_name_from_user_friendly_name(cmp_name)
      # display_name = cmp_name.gsub(/::/,"__")
      sp_hash = {
        cols: [:id, :display_name, :module_branch_id, :type, :ref, :augmented_with_module_info],
        filter: [:and,
                 [:eq, :display_name, display_name],
                 # [:eq, :type, 'instance'],
                 # [:eq, :project_project_id, nil],
                 [:eq, :node_node_id, node_id]]
      }
      cmps = Model.get_objs(cmp_mh, sp_hash, keep_ref_cols: true)

      if namespace
        cmps.select! { |c| (c[:namespace] && c[:namespace][:display_name] == namespace) }
        ret_cmp = cmps.first
      else
        return cmps.first if cmps.size == 1

        opts = Opts.new(with_namespace: true)
        cmp_modules_for_assembly = assembly.list_component_modules(opts)

        cmp_modules_for_assembly.each do |cmp_mod|
          cmps.each do |cmp|
            if cmp_module = cmp[:component_module]
              match_cmps << cmp if cmp_module[:id] == cmp_mod[:id]
            end
          end

          fail ErrorUsage.new('Multiple components matching component name you provided. Please use namespace:component format to delete component!') if match_cmps.size > 1
          ret_cmp = match_cmps.first
        end
      end

      ret_cmp
    end

    def self.get_component_instances_related_by_mixins(components, cols)
      return [] if components.empty?
      sample_cmp = components.first
      component_mh = sample_cmp.model_handle()
      # use base cmp id as equivalence class and find all members of equivalence class to find what each related component is
      # associated with
      cmp_id_to_equiv_class = {}
      equiv_class_members = {}
      ext_cmps = []
      base_cmp_info = []
      components.each do |cmp|
        id = cmp[:id]
        if cmp[:extended_base]
          fail Error.new('cmp[:implementation_id] must be set') unless cmp[:implementation_id]
          ext_cmps << cmp
          extended_base_id = cmp[:extended_base_id]
          base_cmp_info << { id: extended_base_id, node_node_id: cmp[:node_node_id], extended_base: cmp[:extended_base], implementation_id: cmp[:implementation_id] }
          cmp_id_to_equiv_class[id] = (equiv_class_members[extended_base_id] ||= []) << id
        else
          base_cmp_info << { id: cmp[:id] }
          cmp_id_to_equiv_class[id] = (equiv_class_members[id] ||= []) << id
        end
      end

      indexed_ret = {}
      get_components_related_by_mixins_from_extension(component_mh, ext_cmps, cols).each do |found_base_cmp|
        id = found_base_cmp[:id]
        # if found_base_cmp in components dont put in result
        unless cmp_id_to_equiv_class[id]
          indexed_ret[id] = found_base_cmp.merge(assoc_component_ids: equiv_class_members[id])
        end
      end

      get_components_related_by_mixins_from_base(component_mh, base_cmp_info, cols).each do |found_ext_cmp|
        id = found_ext_cmp[:id]
        # if found_ext_cmp in components dont put in result
        unless cmp_id_to_equiv_class[id]
          indexed_ret[id] = found_ext_cmp.merge(assoc_component_ids: equiv_class_members[found_ext_cmp[:extended_base_id]])
        end
      end
      indexed_ret.values
    end

    def self.create_subclass_object(cmp, subclass_model_name = nil)
      cmp && cmp.id_handle().create_object(model_name: subclass_model_name || model_name_with_subclass()).merge(cmp)
    end

    def is_assembly?
      'composite' == get_field?(:type)
    end

    def assembly?(_opts = {})
      if is_assembly?()
        Assembly.create_assembly_subclass_object(self)
      end
    end

    def get_component_i18n_label
      ret = get_stored_component_i18n_label?()
      return ret if ret
      i18n = get_i18n_mappings_for_models(:component)
      i18n_string(i18n, :component, self[:display_name])
    end

    def get_attribute_i18n_label(attribute)
      ret = get_stored_attribute_i18n_label?(attribute)
      return ret if ret
      i18n = get_i18n_mappings_for_models(:attribute, :component)
      i18n_string(i18n, :attribute, attribute[:display_name], self[:component_type])
    end

    def update_component_i18n_label(label)
      update_hash = { id: self[:id], i18n_labels: { i18n_language() => { 'component' => label } } }
      Model.update_from_rows(model_handle, [update_hash], partial_value: true)
    end

    def update_attribute_i18n_label(attribute_name, label)
      update_hash = { id: self[:id], i18n_labels: { i18n_language() => { 'attributes' => { attribute_name => label } } } }
      Model.update_from_rows(model_handle, [update_hash], partial_value: true)
    end

    # self is an instance and it finds a library component
    # multiple_instance_clause is used in case multiple extensions of same type and need to select particular one
    # TODO: extend with logic for multiple_instance_clause
    def get_extension_in_library(extension_type, cols = [:id, :display_name], _multiple_instance_clause = nil)
      base_sp_hash = {
        model_name: :implementation,
        filter: [:eq, :id, self[:implementation_id]],
        cols: [:id, :ancestor_id]
      }
      join_array =
        [
         {
           model_name: :component,
           alias: :library_template,
           join_type: :inner,
           filter: [:eq, :extension_type, extension_type.to_s],
           convert: true,
           join_cond: { implementation_id: :implementation__ancestor_id },
           cols: Aux.array_add?(cols, :implementation_id)
         }
        ]
      rows = Model.get_objects_from_join_array(model_handle(:implementation), base_sp_hash, join_array)
      Log.error('get extension library shoudl only match one component') if rows.size > 1
      rows.first && rows.first[:library_template]
    end

    def get_containing_node_id
      return self[:node_node_id] if self[:node_node_id]
      row = get_objects_from_sp_hash(columns: [:node_node_id, :containing_node_id_info]).first
      row[:node_node_id] || (row[:parent_component] || {})[:node_node_id]
    end

    ####################
    def save_view_in_cache?(type, user_context)
      ViewDefProcessor.save_view_in_cache?(type, id_handle(), user_context)
    end

    ### object processing and access functions
    def get_component_with_attributes_unraveled(attr_filters = { hidden: true })
      sp_hash = { columns: [:id, :display_name, :component_type, :basic_type, :attributes, :i18n_labels] }
      component_and_attrs = get_objects_from_sp_hash(sp_hash)
      return nil if component_and_attrs.empty?
      component = component_and_attrs.first.subset(:id, :display_name, :component_type, :basic_type, :i18n_labels)
      component_attrs = { component_type: component[:component_type], component_name: component[:display_name] }
      filtered_attrs = component_and_attrs.map do |r|
        attr = r[:attribute]
        attr.merge(component_attrs) if attr and not attribute_is_filtered?(attr, attr_filters)
      end.compact
      attributes = AttributeComplexType.flatten_attribute_list(filtered_attrs)
      component.merge(attributes: attributes)
    end

    private

    def sub_item_model_names
      [:node, :component]
    end

    def self.get_components_related_by_mixins_from_extension(component_mh, extension_cmps, cols)
      return [] if extension_cmps.empty?
      base_ids = extension_cmps.map { |cmp| cmp[:instance_extended_base_id] }
      sp_hash = {
        model_name: :component,
        filter: [:oneof, :id, base_ids],
        cols: Aux.array_add?(cols, [:id])
      }
      get_objects_from_sp_hash(component_mh, sp_hash)
    end

    def self.get_components_related_by_mixins_from_base(component_mh, base_cmp_info, cols)
      return [] if base_cmp_info.empty?
      filter =
        if base_cmp_info.size == 1
          extended_base_id_filter(base_cmp_info.first)
        else
          [:or] + base_cmp_info.map { |item| extended_base_id_filter(item) }
        end
      sp_hash = {
        model_name: :component,
        filter: filter,
        cols: Aux.array_add?(cols, [:id])
      }
      get_objects_from_sp_hash(component_mh, sp_hash)
    end

    def self.extended_base_id_filter(base_cmp_info_item)
      if base_cmp_info_item[:extended_base]
        [:and, [:eq, :implementation_id, base_cmp_info_item[:implementation_id]],
         [:eq, :node_node_id, base_cmp_info_item[:node_node_id]],
         [:eq, :extended_base, base_cmp_info_item[:extended_base]]]
      else
      [:eq, :id, base_cmp_info_item[:id]]
      end
    end

    def get_virtual_attributes_aux_extension(attribute_names, cols, field_to_match = :display_name, _multiple_instance_clause = nil)
      component_id = self[:id]
      base_id = self[:extended_base_id]
      sp_hash = {
        model_name: :attribute,
        filter: [:and,
                 [:oneof, field_to_match, attribute_names],
                 [:oneof, :component_component_id, [component_id, base_id]]],
        cols: Aux.array_add?(cols, [:component_component_id, field_to_match])
      }
      attr_mh = model_handle().createMH(:attribute)
      Model.get_objects_from_sp_hash(attr_mh, sp_hash)
    end

    def get_virtual_attributes_aux_base(attribute_names, cols, field_to_match = :display_name, _multiple_instance_clause = nil)
      fail Error.new('Should not be called unless :component_type and :implementation_id are set') unless self[:component_type] && self[:implementation_id]
      component_id = self[:id]
      base_sp_hash = {
        model_name: :component,
        filter: [:and,
                 [:eq, :node_node_id, self[:node_node_id]],
                 [:eq, :implementation_id, self[:implementation_id]],
                 [:or, [:eq, :extended_base, self[:component_type]], [:eq, :id, self[:id]]]],
        cols: [:id, :extended_base, :implementation_id]
      }
      join_array =
        [{
           model_name: :attribute,
           convert: true,
           join_type: :inner,
           filter: [:oneof, field_to_match, attribute_names],
           join_cond: { component_component_id: :component__id },
           cols: Aux.array_add?(cols, [:component_component_id, field_to_match])
         }]
      Model.get_objects_from_join_array(model_handle, base_sp_hash, join_array).map { |r| r[:attribute] }
    end

    # only filters if value is known
    def attribute_is_filtered?(attribute, attr_filters)
      return false if attr_filters.empty?
      attr_filters.each { |k, v| return true if attribute[k] == v }
      false
    end

    public

    def get_view_meta(view_type, virtual_model_ref)
      from_db = get_instance_layout_from_db(view_type)
      virtual_model_ref.set_view_meta_info(from_db[:id], from_db[:updated_at]) if from_db

      layout_def = (from_db || {})[:def] || Layout.create_def_from_field_def(get_field_def(), view_type)
      create_view_meta_from_layout_def(view_type, layout_def)
    end

    def get_view_meta_info(view_type)
      # TODO: can be more efficient (rather than using get_instance_layout_from_db can use something that returns most recent laypout id); also not sure whether if no db hit to return id()
      from_db = get_instance_layout_from_db(view_type)
      return [from_db[:id], from_db[:updated_at]] if from_db
      [id(), Time.new()]
    end

    def get_layouts(view_type)
      from_db = get_layouts_from_db(view_type)
      return from_db unless from_db.empty?
      Layout.create_and_save_from_field_def(id_handle(), get_field_def(), view_type)
      get_layouts_from_db(view_type)
    end

    def add_layout(layout_info)
      Layout.save(id_handle(), layout_info)
    end

    protected

    def get_layouts_from_db(view_type, layout_vc = :layouts)
      unprocessed_rows = get_objects_col_from_sp_hash({ columns: [layout_vc] }, :layout)
      # TODO: more efficient would be to use db sort
      unprocessed_rows.select { |l| l[:type] == view_type.to_s }.sort { |a, b| b[:updated_at] <=> a[:updated_at] }
    end

    def get_instance_layout_from_db(view_type)
      # TODO: more efficient would be to use db limit
      instance_layout = get_layouts_from_db(view_type, :layouts).first
      return instance_layout if instance_layout
      instance_layout = get_layouts_from_db(view_type, :layouts_from_ancestor).first
      return instance_layout if instance_layout
    end

    public

    # TODO: wil be deperacted
    def get_info_for_view_def
      sp_hash = { columns: [:id, :display_name, :component_type, :basic_type, :attributes_view_def_info] }
      component_and_attrs = get_objects_from_sp_hash(sp_hash)
      return nil if component_and_attrs.empty?
      component = component_and_attrs.first.subset_with_vcs(:id, :display_name, :component_type, :basic_type, :view_def_key)
      # if component_and_attrs.first[:attribute] null there shoudl only be one element in component_and_attrs
      return component.merge(attributes: []) unless component_and_attrs.first[:attribute]
      opts = { flatten_nil_value: true }
      component.merge(attributes: AttributeComplexType.flatten_attribute_list(component_and_attrs.map { |r| r[:attribute] }, opts))
    end

    def get_attributes_unraveled(to_set = {}, opts = {})
      sp_hash = {
        filter: [:and,
                 [:eq, :hidden, false]],
        columns: [:id, :display_name, :component_component_id, :attribute_value, :semantic_type, :semantic_type_summary, :data_type, :required, :dynamic, :cannot_change, :port_type, :read_only]
      }
      raw_attributes = get_children_from_sp_hash(:attribute, sp_hash)
      return [] if raw_attributes.empty?
      if to_set.key?(:component_id)
        sample = raw_attributes.first
        to_set[:component_id] = sample[:component_component_id]
      end

      flattened_attr_list = AttributeComplexType.flatten_attribute_list(raw_attributes, opts)
      i18n = get_i18n_mappings_for_models(:attribute)
      flattened_attr_list.map do |a|
        unless a[:hidden]
          name = a[:display_name]
          {
            id: a[:unraveled_attribute_id],
            name: name,
            value: a[:attribute_value],
            i18n: i18n_string(i18n, :attribute, name),
            is_readonly: a.is_readonly?
          }
        end
      end.compact
    end

    def get_virtual_object_attributes(opts = {})
      to_set = { component_id: nil }
      attrs = get_attributes_unraveled(to_set)
      vals = attrs.inject(id: to_set[:component_id]) { |h, a| h.merge(a[:name].to_sym => a[:value]) }
      if opts[:ret_ids]
        ids = attrs.inject({}) { |h, a| h.merge(a[:name].to_sym => a[:id]) }
        return [vals, ids]
      end
      vals
    end

    def add_model_specific_override_attrs!(override_attrs, target_obj)
      # TODO: taking out below to accomidate fact that using ref to qialify whether chef or puppet
      # TODO: think want to add way for components that can have many attributes to have this based on value of the
      # attribut ethat serves as the key
      # override_attrs[:display_name] ||= SQL::ColRef.qualified_ref
      into_node = (target_obj.model_handle[:model_name] == :node)
      override_attrs[:type] ||= (into_node ? 'instance' : 'template')
      override_attrs[:updated] ||= false
    end

    ###### Helper fns
    def get_contained_attribute_ids(opts = {})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      nested_cmps = get_objects(ModelHandle.new(id_handle[:c], :component), nil, parent_id: parent_id)

      (get_directly_contained_object_ids(:attribute) || []) +
      (nested_cmps || []).map { |cmp| cmp.get_contained_attribute_ids(opts) }.flatten()
    end

    # type can be :asserted, :derived or :value
    def get_contained_attribute_values(type, opts = {})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      nested_cmps = get_objects(ModelHandle.new(id_handle[:c], :component), nil, parent_id: parent_id)

      ret = {}
      (nested_cmps || []).each do |cmp|
  values = cmp.get_contained_attribute_values(type, opts)
  if values
    ret[:component] ||= {}
          ret[:component][cmp.get_qualified_ref.to_sym] = values
        end
      end
      dir_vals = get_direct_attribute_values(type, opts)
      ret[:attribute] = dir_vals if dir_vals
      ret
    end

    def get_direct_attribute_values(type, opts = {})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      attr_val_array = Model.get_objects(ModelHandle.new(c, :attribute), nil, parent_id: parent_id)

      return nil if attr_val_array.nil?
      return nil if attr_val_array.empty?
      ret = {}
      attr_type = { asserted: :value_asserted, derived: :value_derived, value: :attribute_value }[type]
      attr_val_array.each do |attr|
        v = { value: attr[attr_type], id: attr[:id] }
        opts[:attr_include].each { |a| v[a] = attr[a] } if opts[:attr_include]
        ret[attr.get_qualified_ref.to_sym] = v
      end
      ret
    end

    def get_objects_associated_nodes
      assocs = Model.get_objects(ModelHandle.new(@c, :assoc_node_component), component_id: self[:id])
      return [] if assocs.nil?
      assocs.map { |assoc| Model.get_object(IDHandle[c: @c, guid: assoc[:node_id]]) }
    end

    def get_obj_with_common_cols
      common_cols =  self.class.common_columns()
      ret = get_objs(cols: common_cols).first
      ret.materialize!(common_cols)
    end

    def get_stored_attribute_i18n_label?(attribute)
      return nil unless self[:i18n_labels]
      ((self[:i18n_labels][i18n_language()] || {})['attributes'] || {})[attribute[:display_name]]
    end

    def get_stored_component_i18n_label?
      return nil unless self[:i18n_labels]
      ((self[:i18n_labels][i18n_language()] || {})['component'] || {})[self[:display_name]]
    end
  end
end
