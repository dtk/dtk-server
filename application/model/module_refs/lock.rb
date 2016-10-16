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
    # This object and its associated table (module.module_ref_lock) captures
    # The locked sha associated with the component module plus cached information on all the service instance's 
    # direct and indirect module refs
    #
    # This object is hash of form
    #  {MODULE_NAME1 => ModuleRef::Lock,
    #   MODULE_NAME2 => ModuleRef::Lock,
    #   ....
    # }
    class Lock < Hash
      require_relative('lock/missing_information')

      attr_reader :assembly_instance
      def initialize(assembly_instance)
        super()
        @assembly_instance = assembly_instance
      end

      # TODO: locked dependencies is minsomer; it is more like 'cached_dependencies'
      AllTypes = [:locked_dependencies, :locked_branch_shas]

      # opts can have
      #  :types (equal to or subset of AllTypes
      #   :with_module_branches - Boolean
      def self.get_all(assembly_instance, opts = {})
        get(assembly_instance, opts[:types] || AllTypes, Aux.hash_subset(opts, [:with_module_branches]))
      end

      # opts can have keys
      #  :augment_with_component_modules (Boolean)
      def self.get_corresponding_aug_module_branches(assembly_instance, opts = {})
        locked_module_refs = get_all(assembly_instance, with_module_branches: true)
        module_branch_mh = assembly_instance.model_handle(:module_branch)
        module_branches = locked_module_refs.values.map do |locked_module_ref|
          info = locked_module_ref[:info]
          unless (info || {})[:module_branch]
            Log.error_pp(['Unexpected that locked_module_ref[:info] is missing :module_branch for', locked_module_ref[:info]])
            nil
          else
            module_branch_hash = info[:module_branch].merge(namespace: info[:namespace], module_name: info[:module_name])
            ModuleBranch.create_stub(module_branch_mh, module_branch_hash)
          end
        end.compact
        augment_with_repos!(module_branches)
        augment_with_component_modules!(module_branches) if opts[:augment_with_component_modules]
        module_branches
      end

      def self.get_implementations(assembly_instance, module_names)
        get(assembly_instance, :locked_dependencies).get_implementations(module_names)
      end

      # TODO: for efficiency can use modification of ModuleRefs::Lock.get(..) that passes in module_name so can filter there
      def self.get_namespace?(assembly_instance, module_name)
        get(assembly_instance, :locked_dependencies).matching_namespace?(module_name)
      end
      def self.get_locked_branch_sha?(assembly_instance, module_name)
        module_ref = get(assembly_instance, :locked_branch_shas)
        [module_ref.matching_locked_branch_sha?(module_name), module_ref.version_branch?(module_name)]
      end
      # returns [namespace, locked_branch_sha]
      def self.get_namespace_and_locked_branch_sha?(assembly_instance, module_name)
        module_refs_lock = get(assembly_instance, AllTypes)
        [module_refs_lock.matching_namespace?(module_name), module_refs_lock.matching_locked_branch_sha?(module_name), module_refs_lock.version_branch?(module_name)]
      end

      # opts can have keys
      # :raise_errors - Boolean
      def self.create_or_update(assembly_instance, opts = {})
        compute_elements(assembly_instance, AllTypes, opts).create_or_update
      end

      def create_or_update
        ModuleRef::Lock.create_or_update(self)
        self
      end

      def matching_namespace?(module_name)
        (el = element?(module_name)) && el.namespace
      end

      def matching_locked_branch_sha?(module_name)
        (module_ref_lock = module_ref_lock(module_name)) && module_ref_lock.locked_branch_sha
      end

      def version_branch?(module_name)
        (module_ref_lock = module_ref_lock(module_name)) && module_ref_lock[:info] && module_ref_lock[:info][:module_branch]
      end

      def elements
        values().map { |module_ref_lock| module_ref_lock_element(module_ref_lock) }.compact
      end

      def get_implementations(module_names)
        ret = []
        module_names.each do |module_name|
          if element = element?(module_name)
            implementations(children_elements(element) + [element]).each do |impl|
              ret << impl unless ret.include?(impl)
            end
          end
        end
        ret
      end

      private

      def self.get_module_refs_lock?(assembly_instance)
        module_ref_locks = ModuleRef::Lock.get(assembly_instance)
        unless  module_ref_locks.empty?
          module_ref_locks.inject(new(assembly_instance)) do |h, module_ref_lock|
            h.merge(module_ref_lock.module_name => module_ref_lock)
          end
        end
      end

      # opts can have keys
      #   :with_module_branches - Boolean
      def self.get(assembly_instance, types, opts = {})
        types = Array(types)
        if persisted = get_module_refs_lock?(assembly_instance)
          if missing_info = MissingInformation.missing_information?(persisted, types, opts)
            Log.error_pp(["Unexpected that there is info missing from ModuleRefs::Lock info must be computed for assembly", assembly_instance, missing_info])
          end
          persisted
        else
          Log.error_pp(["Unexpected that the ModuleRefs::Lock info must be computed for assembly", assembly_instance]) 
          compute_elements(assembly_instance, types, opts)
        end
      end

      # opts can have keys
      #   :with_module_branches - Boolean
      #   :raise_errors - Boolean
      #   :version
      def self.compute_elements(assembly_instance, types, opts = {})
        module_refs_tree = ModuleRefs::Tree.create(assembly_instance, opts)
        collapsed = module_refs_tree.collapse(Aux.hash_subset(opts, [:raise_errors]))
        collapsed.choose_namespaces_and_versions!()
        collapsed.add_implementations!(assembly_instance, opts)

        ret = new(assembly_instance)
        collapsed.each_pair do |module_name, single_el_array|
          if single_el_array.empty?
            Log.error('Unexpected that single_el_array is empty')
          else
            if single_el_array.size > 1
              Log.error('Unexpected that single_el_array has size > 1; picking first')
            end
            ret[module_name] = ModuleRef::Lock.create_from_element(assembly_instance, single_el_array.first)
          end
        end

        if types.include?(:locked_branch_shas) || opts[:with_module_branches]
          add_matching_module_branches!(ret)
        end
        if types.include?(:locked_branch_shas)
          # requires add_matching_module_branches!(ret)
          add_locked_branch_shas?(ret)
        end

        ret
      end

      def self.add_locked_branch_shas?(locked_module_refs)
        locked_module_refs.each_pair do |_module_name, module_ref_lock|
          if el = module_ref_lock_element(module_ref_lock)
            if mb = el.module_branch
              if sha = mb[:current_sha]
                module_ref_lock.locked_branch_sha = sha
              end
            end
          end
        end
        locked_module_refs
      end

      def self.add_matching_module_branches!(locked_module_refs)
        ret = locked_module_refs
        ndx_els = {}
        disjuncts = []
        locked_module_refs.elements.each do |el|
          if impl = el.implementation
            unless el.module_branch
              disjuncts << [:and, [:eq, :repo_id, impl[:repo_id]], [:eq, :branch, impl[:branch]]]
              ndx = "#{impl[:repo_id]}:#{impl[:branch]}"
              ndx_els[ndx] = el
            end
          end
        end

        return ret if disjuncts.empty?
        sp_hash = {
          cols: [:id, :group_id, :display_name, :component_id, :branch, :repo_id, :current_sha, :version, :dsl_parsed, :frozen],
          filter: [:or] + disjuncts
        }

        mh = locked_module_refs.assembly_instance.model_handle(:module_branch)
        Model.get_objs(mh, sp_hash).each do |mb|
          ndx = "#{mb[:repo_id]}:#{mb[:branch]}"
          if el = ndx_els[ndx]
            el.module_branch = mb
          end
        end
        ret
      end
      def module_ref_lock(module_name)
        self[module_name]
      end

      def element?(module_name)
        module_ref_lock_element(module_ref_lock(module_name))
      end

      def element(module_name)
        element?(module_name) || (Log.error("Unexpected that no match for module name '#{module_name}'"); nil)
      end

      def module_ref_lock_element(module_ref_lock)
        self.class.module_ref_lock_element(module_ref_lock)
      end
      def self.module_ref_lock_element(module_ref_lock)
        module_ref_lock && module_ref_lock.info
      end

      def children_elements(parent_element)
        parent_element.children_module_names.map { |mn| element?(mn) }.compact
      end

      def implementations(elements)
        elements.map { |el| self.class.implementation(el) }.compact
      end
      def self.implementation(element)
        element.implementation ||
          (Log.error("Unexpected that the module '#{element.namespace}:#{element.module_name}' does not have an corresponding implementation object"); nil)
      end

      def self.augment_with_repos!(module_branches)
        return module_branches if module_branches.empty?
        repo_mh = module_branches.first.model_handle(:repo)
        sp_hash = {
          cols: [:id, :group_id, :display_name, :repo_name, :local_dir],
          filter: [:oneof, :id, module_branches.map { |mb| mb[:repo_id] }]
        }
        ndx_repos = Model.get_objs(repo_mh, sp_hash).inject({}) { |h, repo| h.merge(repo.id => repo) }
        module_branches.each do |module_branch|
          module_branch[:repo] = ndx_repos[module_branch[:repo_id]]
        end
        module_branches
      end

      def self.augment_with_component_modules!(module_branches)
        return module_branches if module_branches.empty?
        component_module_mh = module_branches.first.model_handle(:component_module)
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:oneof, :id, module_branches.map { |mb| mb[:component_id] }]
        }
        ndx_component_modules = Model.get_objs(component_module_mh, sp_hash).inject({}) do |h, component_module| 
          h.merge(component_module.id => component_module) 
        end
        module_branches.each do |module_branch|
          module_branch[:component_module] = ndx_component_modules[module_branch[:component_id]]
        end
        module_branches
      end

    end
  end
end
