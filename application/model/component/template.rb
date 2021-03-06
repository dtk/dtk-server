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
    require_relative('template/augmented')
    require_relative('template/match_element')

    extend MatchElement::ClassMixin

    def self.get_objs(mh, sp_hash, opts = {})
      if mh[:model_name] == :component_template
        super(mh.merge(model_name: :component), sp_hash, opts).map { |cmp| create_from_component(cmp) }
      else
        super
      end
    end

    def self.create_from_component(cmp)
      cmp && cmp.id_handle.create_object(model_name: :component_template).merge(cmp)
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
      clone_info = self.class.get_info_for_clone([id_handle]).first
      merge!(clone_info)
    end

    def get_current_sha!
      unless module_branch = self[:module_branch]
        Log.error('Unexpected that get_current_sha called on object when self[:module_branch] not set')
        return nil
      end
      module_branch[:current_sha] || module_branch.update_current_sha_from_repo!
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
      rows = get_objs(cmp_tmpl_idhs.first.createMH, sp_hash)
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

    def self.list(project, opts = {})
      assembly = opts[:assembly_instance]
      filter   = [
        :and,
        [:eq, :type, 'template'],
        [:eq, :project_project_id, project.id]
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
        fail ErrorIdInvalid.new(id, pp_object_type)
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
        fail ErrorNameDoesNotExist.new(name, pp_object_type)
      else
        name_to_id_aux(model_handle, name, version_or_versions)
      end
    end

    private

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
      mh = component_templates.first.model_handle
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

    module Mixin
      def update_default(attribute_name, val, field_to_match = :display_name)
        tmpl_attr_obj =  get_virtual_attribute(attribute_name, [:id, :value_asserted], field_to_match)
        fail Error.new("cannot find attribute #{attribute_name} on component template") unless tmpl_attr_obj
        update(updated: true)
        tmpl_attr_obj.update(value_asserted: val)
        # update any instance that points to this template, which does not have an instance value asserted
        # TODO: can be more efficient by doing selct and update at same time
        base_sp_hash = {
          model_name: :component,
          filter: [:eq, :ancestor_id, id],
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
  end
end; end
