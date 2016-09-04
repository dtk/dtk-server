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
module DTK; class Component
  class Template < self
    def self.get_objs(mh, sp_hash, opts = {})
      if mh[:model_name] == :component_template
        super(mh.merge(model_name: :component), sp_hash, opts).map { |cmp| create_from_component(cmp) }
      else
        super
      end
    end

    def self.create_from_component(cmp)
      cmp && cmp.id_handle().create_object(model_name: :component_template).merge(cmp)
    end

    def self.get_info_for_clone(cmp_template_idhs)
      ret = []
      return ret if cmp_template_idhs.empty?
      sp_hash = {
        cols: [:id, :group_id, :display_name, :project_project_id, :component_type, :version, :module_branch],
        filter: [:oneof, :id, cmp_template_idhs.map(&:get_id)]
      }
      mh = cmp_template_idhs.first.createMH(:component_template)
      ret = get_objs(mh, sp_hash)
      ret.each(&:get_current_sha!)
      ret
    end

    def update_with_clone_info!
      clone_info = self.class.get_info_for_clone([id_handle()]).first
      merge!(clone_info)
    end

    def get_current_sha!
      unless module_branch = self[:module_branch]
        Log.error('Unexpected that get_current_sha called on object when self[:module_branch] not set')
        return nil
      end
      module_branch[:current_sha] || module_branch.update_current_sha_from_repo!()
    end

    def get_component_module
      get_obj_helper(:component_module)
    end

    # returns non-nil only if this is a component that takes a title and if so returns the attribute object that stores the title
    def get_title_attribute_name?
      rows = self.class.get_title_attributes([id_handle])
      rows.first[:display_name] unless rows.empty?
    end

    # for any member of cmp_tmpl_idhs that is a non-singleton, it returns the title attribute
    def self.get_title_attributes(cmp_tmpl_idhs)
      ret = []
      return ret if cmp_tmpl_idhs.empty?
      # first see if not only_one_per_node and has the default attribute
      sp_hash = {
        cols: [:attribute_default_title_field],
        filter: [:and, [:eq, :only_one_per_node, false],
                 [:oneof, :id, cmp_tmpl_idhs.map(&:get_id)]]
      }
      rows = get_objs(cmp_tmpl_idhs.first.createMH(), sp_hash)
      return ret if rows.empty?

      # rows will have element for each element of cmp_tmpl_idhs that is non-singleton
      # element key :attribute will be nil if it does not use teh default key; for all
      # these we need to make the more expensive call Attribute.get_title_attributes
      need_title_attrs_cmp_idhs = rows.select { |r| r[:attribute].nil? }.map(&:id_handle)
      ret = rows.map { |r| r[:attribute] }.compact
      unless need_title_attrs_cmp_idhs.empty?
        attr_cols = [:id, :group_id, :display_name, :external_ref, :component_component_id]
        title_attrs = get_attributes(need_title_attrs_cmp_idhs, cols: attr_cols).select(&:is_title_attribute?)
        unless title_attrs.empty?
          ret += title_attrs
        end
      end
      ret
    end

    class MatchElement < Hash
      def initialize(hash)
        super()
        replace(hash)
      end

      def component_type
        self[:component_type]
      end

      def version_field
        self[:version_field]
      end

      def version
        self[:version]
      end

      def namespace
        self[:namespace]
      end
    end
    def self.get_matching_elements(project_idh, match_element_array, opts = {})
      ret = []
      cmp_types = match_element_array.map(&:component_type).uniq
      versions = match_element_array.map(&:version_field)
      sp_hash = {
        cols: [:id, :group_id, :component_type, :version, :implementation_id, :external_ref],
        filter: [:and,
                 [:eq, :project_project_id, project_idh.get_id()],
                 [:oneof, :version, versions],
                 [:eq, :assembly_id, nil],
                 [:eq, :node_node_id, nil],
                 [:oneof, :component_type, cmp_types]]
      }
      component_rows = get_objs(project_idh.createMH(:component), sp_hash)
      augment_with_namespace!(component_rows)
      ret = []
      unmatched = []
      match_element_array.each do |el|
        matches = component_rows.select do |r|
          el.version_field == r[:version] &&
            el.component_type == r[:component_type] &&
            (el.namespace.nil? || el.namespace == r[:namespace])
        end
        if matches.empty?
          unmatched << el
        elsif matches.size == 1
          ret << matches.first
        else
          # TODO: may put in logic that sees if one is service modules ns and uses that one when multiple matches
          module_name = Component.module_name(el.component_type)
          error_params = {
            module_type: 'component',
            module_name: Component.module_name(el.component_type),
            namespaces: matches.map { |m| m[:namespace] }.compact # compact just to be safe
          }
          fail ServiceModule::ParsingError::AmbiguousModuleRef.new(error_params)
        end
      end
      unless unmatched.empty?()
        # TODO: indicate whether there is a nailed namespace that does not exist or no matches at all
        cmp_refs = unmatched.map do |match_el|
          cmp_type = match_el.component_type
          if ns = match_el.namespace
            cmp_type = "#{ns}:#{cmp_type}"
          end
          {
            component_type: cmp_type,
            version: match_el.version
          }
        end
        if opts[:service_instance_module]
          fail ServiceModule::ParsingError::RemovedServiceInstanceCmpRef.new(cmp_refs, opts)
        else
          fail ServiceModule::ParsingError::DanglingComponentRefs.new(cmp_refs, opts)
        end
      end
      ret
    end

    def self.list(project, opts = {})
      assembly = opts[:assembly_instance]
      filter   = [
        :and,
        [:eq, :type, 'template'],
        # had to remove this to display other versions beside master
        # [:oneof, :version, filter_on_versions(assembly: assembly)],
        [:eq, :project_project_id, project.id()]
      ]

      sp_hash = {
        cols: [:id, :type, :display_name, :description, :component_type, :version, :refnum, :module_branch_id],
        filter: filter
      }
      cmps = get_objs(project.model_handle(:component), sp_hash, keep_ref_cols: true)

      ingore_type = opts[:ignore]
      hide_assembly_cmps = opts[:hide_assembly_cmps]

      ret = []
      cmps.each do |r|
        sp_h = {
          cols: [:id, :type, :display_name, :component_module_namespace_info],
          filter: [:eq, :id, r[:module_branch_id]]
        }
        m_branch = Model.get_obj(project.model_handle(:module_branch), sp_h)

        # with (hide_assembly_cmps && !ModuleVersion.assembly_module_version?(r[:version])) we eliminate assembly instance components
        if (m_branch && !m_branch[:type].eql?(ingore_type) && (hide_assembly_cmps && !ModuleVersion.assembly_module_version?(r[:version])))
          branch_namespace = m_branch[:namespace]
          r[:namespace] = branch_namespace[:display_name]
          ret << r
        end
      end

      if constraint = opts[:component_version_constraints]
        ret = ret.select { |r| constraint.meets_constraint?(r) }
      end
      ret.each(&:convert_to_print_form!)
      ret.sort { |a, b| a[:display_name] <=> b[:display_name] }
    end

    def self.check_valid_id(model_handle, id, version_or_versions = nil)
      if version_or_versions.is_a?(Array)
        version_or_versions.each do |version|
          if ret = check_valid_id_aux(model_handle, id, version, no_error_if_no_match: true)
            return ret
          end
        end
        fail ErrorIdInvalid.new(id, pp_object_type())
      else
        check_valid_id_aux(model_handle, id, version_or_versions)
      end
    end

    def self.check_valid_id_aux(model_handle, id, version, opts = {})
      filter =
        [:and,
         [:eq, :id, id],
         [:eq, :type, 'template'],
         [:eq, :node_node_id, nil],
         [:neq, :project_project_id, nil],
         [:eq, :version, version_field(version)]]
      check_valid_id_helper(model_handle, id, filter, opts)
    end

    # if title is in the name, this strips it off
    def self.name_to_id(model_handle, name, version_or_versions = nil)
      if version_or_versions.is_a?(Array)
        version_or_versions.each do |version|
          if ret = name_to_id_aux(model_handle, name, version, no_error_if_no_match: true)
            return ret
          end
        end
        fail ErrorNameDoesNotExist.new(name, pp_object_type())
      else
        name_to_id_aux(model_handle, name, version_or_versions)
      end
    end

    # This method returns an augmented_component_template if a unique match is found; this is a component template augmented with keys:
    #   :module_branch
    #   :component_module
    #   :namespace
    # if no match is found then nil is returned otherwise error raised indicating multiple matches found
    # opts can have keys:
    #   :namespace
    #   :use_base_template
    def self.get_augmented_component_template?(assembly, cmp_name, opts = {})
      ret_cmp = nil
      matching_cmp_templates = find_matching_component_templates(assembly, cmp_name, opts)

      if matching_cmp_templates.empty?
        return ret_cmp
      elsif matching_cmp_templates.size > 1
        possible_names = matching_cmp_templates.map { |r| r.display_name_print_form(namespace_prefix: true) }.join(',')
        fail ErrorUsage.new("Multiple components with different namespaces or/and versions match. You have to specify namespace or version.")
      end
      ret_cmp = matching_cmp_templates.first

      # if component_template with same name exist but have different namespace, return error message that user should
      # use component_template from module that already exist in service instance
      opts = Opts.new(with_namespace: true)
      assembly_cmp_mods = assembly.list_component_modules(opts) # component_modules already associated with service instance
      ret_cmp_mod = ret_cmp[:component_module][:display_name]
      if cmp_mod = assembly_cmp_mods.find { |cmp_mod| cmp_mod[:display_name] == ret_cmp_mod }
        ret_cmp_ns = ret_cmp[:namespace][:display_name]
        cmp_mod_ns = cmp_mod[:namespace_name]
        if ret_cmp_ns != cmp_mod_ns
          fail ErrorUsage.new("Unable to add component from (#{ret_cmp_ns}:#{ret_cmp_mod}) because you are already using components from following component modules: #{cmp_mod_ns}:#{cmp_mod[:display_name]}")
        end

        ret_cmp_version = ret_cmp[:version]
        cmp_mod_version = cmp_mod[:display_version]||cmp_mod[:module_branch][:version]
        full_ret_cmp_name = (ret_cmp_version && ret_cmp_version!='master') ? "#{ret_cmp_ns}:#{ret_cmp_mod}:#{ret_cmp_version}" : "#{ret_cmp_ns}:#{ret_cmp_mod}"
        full_cmp_mod_name = (cmp_mod_version && cmp_mod_version!='master') ? "#{cmp_mod_ns}:#{cmp_mod[:display_name]}:#{cmp_mod_version}" : "#{cmp_mod_ns}:#{cmp_mod[:display_name]}"
        fail ErrorUsage.new("Unable to add component from (#{full_ret_cmp_name}) because you are already using components version: #{full_cmp_mod_name}") if ret_cmp_version != cmp_mod_version
      end
      ret_cmp
    end

    # This method returns an array with zero or more matching augmented component templates
    # opts can have keys
    #   :namespace
    #   :use_base_template
    def self.find_matching_component_templates(assembly, cmp_name, opts = {})
      ret = []
      display_name = display_name_from_user_friendly_name(cmp_name)
      component_type, title, version =  ComponentTitle.parse_component_display_name(display_name, return_version: true)
      sp_hash = {
        cols: [:id, :group_id, :display_name, :module_branch_id, :type, :ref, :augmented_with_module_info, :version],
        filter: [:and,
                 [:eq, :type, 'template'],
                 [:eq, :component_type, component_type],
                 [:neq, :project_project_id, nil],
                 [:oneof, :version, filter_on_versions(assembly: assembly, version: version)],
                 [:eq, :node_node_id, nil]]
      }
      ret = get_objs(assembly.model_handle(:component_template), sp_hash, keep_ref_cols: true)
      if namespace = opts[:namespace]
        # filter component templates by namepace
        ret.select! { |cmp| cmp[:namespace][:display_name] == namespace }
      end
      ret
      return ret if ret.empty?

      # there could be two matches one from base template and one from service insatnce specific template; in
      # this case use service specfic one
      assembly_version = assembly_version(assembly)
      if ret.find { |cmp| cmp[:version] == assembly_version }
        if opts[:use_base_template]
          ret.reject! { |cmp| cmp[:version] == assembly_version }
        else
          ret.select! { |cmp| cmp[:version] == assembly_version }
        end
      end

      ret
    end

    private

    def self.assembly_version(assembly)
      ModuleVersion.ret(assembly)
    end
    def self.filter_on_versions(opts)
      ret      = []
      version  = opts[:version]
      assembly = opts[:assembly]

      if version
        ret << version.gsub!(/\(|\)/,'')
      elsif assembly
        ret << 'master'
        ret << assembly_version(assembly)
      end

      ret.compact
    end

    # if title is in the name, this strips it off
    def self.name_to_id_aux(model_handle, name, version, opts = {})
      display_name = display_name_from_user_friendly_name(name)
      component_type, title =  ComponentTitle.parse_component_display_name(display_name)
      sp_hash = {
        cols: [:id],
        filter: [:and,
                 [:eq, :type, 'template'],
                 [:eq, :component_type, component_type],
                 [:neq, :project_project_id, nil],
                 [:eq, :node_node_id, nil],
                 [:eq, :version, version_field(version)]]
      }
      name_to_id_helper(model_handle, Component.name_with_version(name, version), sp_hash, opts)
    end

    def self.augment_with_namespace!(component_templates)
      ret = []
      return ret if component_templates.empty?
      sp_hash = {
        cols: [:id, :namespace_info],
        filter: [:oneof, :id, component_templates.map(&:id)]
      }
      mh = component_templates.first.model_handle()
      ndx_namespace_info = get_objs(mh, sp_hash).inject({}) do |h, r|
        h.merge(r[:id] => (r[:namespace] || {})[:display_name])
      end
      component_templates.each do |r|
        if namespace = ndx_namespace_info[r[:id]]
          r.merge!(namespace: namespace)
        end
      end
      component_templates
    end
  end

  # TODO: may move to be instance method on Template
  module TemplateMixin
    def update_default(attribute_name, val, field_to_match = :display_name)
      tmpl_attr_obj =  get_virtual_attribute(attribute_name, [:id, :value_asserted], field_to_match)
      fail Error.new("cannot find attribute #{attribute_name} on component template") unless tmpl_attr_obj
      update(updated: true)
      tmpl_attr_obj.update(value_asserted: val)
      # update any instance that points to this template, which does not have an instance value asserted
      # TODO: can be more efficient by doing selct and update at same time
      base_sp_hash = {
        model_name: :component,
        filter: [:eq, :ancestor_id, id()],
        cols: [:id]
      }
      join_array =
        [{
           model_name: :attribute,
           convert: true,
           join_type: :inner,
           filter: [:and, [:eq, field_to_match, attribute_name], [:eq, :is_instance_value, false]],
           join_cond: { component_component_id: :component__id },
           cols: [:id, :component_component_id]
         }]
      attr_ids_to_update = Model.get_objects_from_join_array(model_handle, base_sp_hash, join_array).map { |r| r[:attribute][:id] }
      unless attr_ids_to_update.empty?
        attr_mh = createMH(:attribute)
        attribute_rows = attr_ids_to_update.map { |attr_id| { id: attr_id, value_asserted: val } }
        Attribute.update_and_propagate_attributes(attr_mh, attribute_rows)
      end
    end
  end
end; end
