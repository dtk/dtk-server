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
module DTK
  class ModuleRefs
    require_relative('module_refs/mixin')
    require_relative('module_refs/parse')
    require_relative('module_refs/component_dsl_form')
    require_relative('module_refs/matching_templates')
    require_relative('module_refs/tree')
    require_relative('module_refs/lock')
    include MatchingTemplatesMixin

    attr_reader :parent, :component_modules
    def initialize(parent, content_hash_form, opts = {})
      @parent            = parent
      @component_modules =  opts[:content_hash_form_is_reified] ?
        content_hash_form :
        Parse.reify_content(parent.model_handle(:model_ref), content_hash_form)
    end
    private :initialize

    # This finds module refs that matches branches
    def self.get_multiple_component_module_refs(branches)
      ndx_branches = branches.inject({}) { |h, r| h.merge(r[:id] => r) }
      ModuleRef.get_ndx_component_module_ref_arrays(branches).map do |(branch_id, cmr_array)|
        content_hash_content = cmr_array.inject({}) { |h, r| h.merge(key(r[:module_name]) => r) }
        new(ndx_branches[branch_id], content_hash_content)
      end
    end

    def self.get_component_module_refs(branch)
      common_module_branch = branch.common_module_branch

      content_hash_content = ModuleRef.get_component_module_ref_array(common_module_branch).inject({}) do |h, r|
        h.merge(key(r[:module_name]) => r)
      end

      # TODO: we do not support version to be set to 'master', instead we expect nil
      content_hash_content.each do |k,v|
        v[:version_info] = nil if v[:version_info] == 'master'
      end

      new(common_module_branch, content_hash_content)
    end

    def self.get_module_refs_by_name_and_version(branch, ref_namespace, ref_name, ref_version = nil)
      mh     = branch.model_handle(:module_ref)
      filter = [:and, [:eq, :module_name, ref_name], [:eq, :namespace_info, ref_namespace], [:eq, :version_info, ref_version]]

      component_sp_hash = {
        cols: [:is_dependency_to_component_modules],
        filter: filter
      }
      component_modules = Model.get_objs(mh, component_sp_hash)

      service_sp_hash = {
        cols: [:is_dependency_to_service_modules],
        filter: filter
      }
      service_modules = Model.get_objs(mh, service_sp_hash)

      [component_modules, service_modules]
    end

    # returns true if an update made; this updates the ruby object
    # each element in the array cmp_modules_with_namespaces
    # is a component module object with the added field :namespace_name
    # TODO: DTK-2046
    # make change here so argument has external_ref info; so might pass in as argument module_ref objects
    # This might require the persistent module refs to be there
    def update_object_if_needed!(cmp_modules_with_namespaces, opts = {})
      ret              = false
      module_ref_diffs = get_module_ref_diffs(cmp_modules_with_namespaces)

      if to_delete = module_ref_diffs[:delete]
        to_delete.each { |cmp_mod| delete_component_module_ref(cmp_mod[:display_name]) }
        ret = true
      end

      if to_add = module_ref_diffs[:add]
        to_add.each { |cmp_mod| add_or_set_component_module_ref(cmp_mod[:display_name], {namespace_info: cmp_mod[:namespace_name], version_info: cmp_mod[:version_info]}) }
        ret = true
      end

      ret
    end

    # serializes and saves object to repo
    def serialize_and_save_to_repo?(opts = {})
      dsl_hash_form = dsl_hash_form()
      if !dsl_hash_form.empty? || opts[:ambiguous] || opts[:possibly_missing] || opts[:create_empty_module_refs]
        self.parent.serialize_and_save_to_repo?(meta_filename_path, dsl_hash_form, nil, opts)
      end
    end

    def component_module_ref?(cmp_module_name)
      self.component_modules[key(cmp_module_name)]
    end

    def matching_component_module_namespace?(cmp_module_name)
      if module_ref = component_module_ref?(key(cmp_module_name))
        module_ref.namespace
      end
    end

    def version_objs_indexed_by_modules
      ret = {}
      component_modules.each_pair do |mod, cmr|
        if version_info =  cmr[:version_info]
          ret.merge!(mod.to_s => version_info)
        end
      end
      ret
    end

    def update_component_template_ids(component_module)
      # first get filter so can call get_augmented_component_refs
      assembly_templates = component_module.get_associated_assembly_templates
      return if assembly_templates.empty?
      filter = [:oneof, :id, assembly_templates.map { |r| r[:id] }]
      opts = {
        filter: filter,
        component_module_refs: self,
        force_compute_template_id: true
      }
      aug_cmp_refs = Assembly::Template.get_augmented_component_refs(component_module.model_handle(:component), opts)
      return if aug_cmp_refs.empty?
      cmp_ref_update_rows = aug_cmp_refs.map { |r| r.hash_subset(:id, :component_template_id) }
      Model.update_from_rows(component_module.model_handle(:component_ref), cmp_ref_update_rows)
    end

    def has_module_version?(cmp_module_name, version_string)
      if cmp_module_ref = component_module_ref?(cmp_module_name)
        cmp_module_ref.version_string == version_string
      end
    end

    def include_module?(cmp_module_name)
      component_modules.key?(key(cmp_module_name))
    end

    def ret_service_module_info
      sp_hash = {
        cols: [:service_module_info]
      }
      get_obj(sp_hash)
    end

    def set_module_version(cmp_module_name, version)
      key = key(cmp_module_name)
      if cmr = self.component_modules[key]
        cmr.set_module_version(version)
      else
        hash_content = {
          component_module: cmp_module_name,
          version_info: version
        }
        self.component_modules[key] = ModuleRef.reify(self.parent.model_handle, hash_content)
      end
      ModuleRef.update(:create_or_update, self.parent, self.component_modules.values)
    end

    def update
      module_ref_hash_array = self.component_modules.map do |(key, hash)|
        el = hash
        unless hash[:module_name]
          el = el.merge(module_name: key.to_s)
        end
        unless hash[:module_type]
          el = el.merge(module_type: 'component')
        end
        el
      end
      ModuleRef.create_or_update(self.parent, module_ref_hash_array)
    end

    def self.clone_component_module_refs(base_branch, new_branch)
      cmrs = get_component_module_refs(base_branch)
      ModuleRef.create_or_update(new_branch, cmrs.component_modules.values)
    end

    def get_module_ref_diffs(cmp_modules_with_namespaces)
      diffs             = {}
      refs_w_namespaces = module_refs_to_modules_with_namespaces

      cmp_modules_with_namespaces.each do |cmp_mod|
        [:display_name, :namespace_name].each do |key|
          fail Error.new("Unexpected that cmp_modules_with_namespaces element does not have key: #{key}") unless cmp_mod[key]
        end

        if !refs_w_namespaces.include?(cmp_mod)
          (diffs[:add] ||= []) << cmp_mod
        end
      end

      to_delete = refs_w_namespaces - cmp_modules_with_namespaces
      to_delete.reject!{ |cmp_mod| IgnoreReservedModules.include?("#{cmp_mod[:namespace_name]}:#{cmp_mod[:display_name]}") }

      unless to_delete.empty?
        diffs[:delete] = to_delete
      end

      diffs
    end
    IgnoreReservedModules = ['aws:ec2']

    protected

    def project_idh
      @project_idh ||= self.parent.get_module.get_project.id_handle
    end


    private

    def self.update(parent, cmp_modules)
      ModuleRef.create_or_update(parent, cmp_modules.values)
    end

    def add_or_set_component_module_ref(cmp_module_name, mod_ref_hash)
      self.component_modules[key(cmp_module_name)] = ModuleRef.reify(self.parent.model_handle, mod_ref_hash)
    end

    def delete_component_module_ref(cmp_module_name)
      self.component_modules.delete(key(cmp_module_name))
    end

    def self.key(el)
      el.to_sym
    end
    def key(el)
      self.class.key(el)
    end

    def self.isa_dsl_filename?(path)
      path == meta_filename_path
    end
    def meta_filename_path
      self.class.meta_filename_path
    end
    def self.meta_filename_path
      ServiceModule::DSLParser.default_rel_path?(:component_module_refs) ||
        fail(Error.new('Unexpected that cannot compute a meta_filename_path for component_module_refs'))
    end

    def dsl_hash_form
      ret = SimpleOrderedHash.new
      dsl_hash_form = {}
      component_modules.each_pair do |cmp_module_name, cmr|
        hf = cmr.dsl_hash_form
        dsl_hash_form[cmp_module_name.to_s] = hf unless hf.empty?
      end

      if dsl_hash_form.empty?
        return ret
      end

      sorted_dsl_hash_form = dsl_hash_form.keys.map(&:to_s).sort.inject(SimpleOrderedHash.new) do |h, k|
        h.merge(k => dsl_hash_form[k])
      end
      ret.merge(component_modules: sorted_dsl_hash_form)
    end

    class ComponentTypeToCheck < Array
      def mapping_required?
        find { |r| r[:required] }
      end
    end

    def module_refs_to_modules_with_namespaces
      component_modules.map { |_name, ref| { display_name: ref[:display_name], namespace_name: ref[:namespace_info], version_info: (ref[:version_info] || 'master').to_s } }
    end
  end
end
