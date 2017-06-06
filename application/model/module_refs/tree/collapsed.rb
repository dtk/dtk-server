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
module DTK; class ModuleRefs
  class Tree
    class Collapsed < Hash
      # TODO: DTK-2267: need to handle case where same namespace but different versions
      # Must make sure that the method collapse does not remove all but the first version found
      # Must Update choose_namespaces_and_versions! (which was renamed from choose_namespaces!)
      # resolves conflict when multiple versions of same namespace/module pair by picking latest version
      # if they can be ordered

      module Mixin
        def collapse(opts = {})
          ret = Collapsed.new
          level = opts[:level] || 1
          @module_refs.each_pair do |module_name, subtree|
            if missing_module_ref = subtree.isa_missing_module_ref?()
              if opts[:raise_errors]
                fail missing_module_ref.error()
              else
                next
              end
            end

            children_module_names = []
            opts_subtree = Aux.hash_subset(opts, [:raise_errors]).merge(level: level + 1)
            subtree.collapse(opts_subtree).each_pair do |subtree_module_name, subtree_els|
              collapsed_tree_els = ret[subtree_module_name] ||= []
              subtree_els.each do |subtree_el|
                unless collapsed_tree_els.find { |el| el == subtree_el }
                  collapsed_tree_els << subtree_el
                end
                subtree_el.children_and_this_module_names().each do |st_module_name|
                  children_module_names << st_module_name unless children_module_names.include?(st_module_name)
                end
              end
            end

            if namespace = subtree.namespace()
              opts_create = { children_module_names: children_module_names }
              if external_ref = subtree.external_ref?()
                opts_create.merge!(external_ref: external_ref)
              end
              if version = subtree.version?
                opts_create.merge!(version: version)
              end
              (ret[module_name] ||= []) << ModuleRef::Lock::Info.new(namespace, module_name, level, opts_create)
            end
          end
          ret
        end
      end

      # opts[:stratagy] can be
      #  :pick_first_level - if multiple and have first level one then use that otherwise will randomly pick top one
      def choose_namespaces_and_versions!(opts = {})
        strategy = opts[:strategy] || DefaultStrategy
        if strategy == :pick_first_level
          choose_namespaces__pick_first_level!(opts)
        else
          fail Error.new("Currently not supporting namespace resolution strategy '#{strategy}'")
        end
      end
      DefaultStrategy = :pick_first_level

      def add_implementations!(assembly_instance)
        ndx_impls = get_relevant_ndx_implementations(assembly_instance)
        each_element do |el|
          version = el.version || Implementation.version_field
          ndx = impl_index(el.namespace, el.module_name, version)
          if impl = ndx_impls[ndx]
            el.implementation = impl
          else
            Log.error("Unexpected that cannot find index '#{ndx}' in ndx_impls")
          end
        end
        self
      end

      private

      # returns implementations indexed by NS:MOD:VERSION
      def get_relevant_ndx_implementations(assembly_instance)
        disjuncts = []
        each_element do |el|
          disjunct =
            [:and,
             [:eq, :module_name, el.module_name],
             [:eq, :module_namespace, el.namespace]
            ]
          disjuncts << disjunct
        end
        filter = ((disjuncts.size == 1) ? disjuncts.first : ([:or] + disjuncts))
        sp_hash = {
          cols: [:id, :group_id, :display_name, :repo, :repo_id, :branch, :module_name, :module_namespace, :version],
          filter: filter
        }

        # get the implementations that meet sp_hash, but if have two matches for a module_name/module_namespace pair
        # return just one that matches the assembly version
        ret = {}
        assembly_version = ModuleVersion.ret(assembly_instance)
        Model.get_objs(assembly_instance.model_handle(:implementation), sp_hash).each do |impl|
          # if version is an assembly_module_version, reject if not associated with this assembly
          # else (a base version); reject if coresponding assembly_module_version has been saved already
          version = impl[:version]
          case version_type(version, assembly_version)
           when :non_matching_assembly_module
             # no op
           when :matching_assembly_module
            update_if_not_set!(ret, impl)
            # Also put impl under key that represents base version
            base_version = assembly_version.corresponding_base_version(version)
            update_corresponding_base_version!(ret, impl, base_version)
           when :base_version
            update_if_not_set!(ret, impl)
          end
        end
        ret
      end

      def version_type(version, assembly_version)
        unless ModuleVersion.assembly_module_version?(version)
          :base_version
        else
          assembly_version.match?(version) ? :matching_assembly_module : :non_matching_assembly_module
        end
      end


      def update_if_not_set!(ret, impl)
        ndx = impl_index(impl[:module_namespace], impl[:module_name], impl[:version])
        ret[ndx] ||= impl
      end

      def update_corresponding_base_version!(ret, impl, base_version)
        base_version_ndx = impl_index(impl[:module_namespace], impl[:module_name], base_version)
        # '=' so will override
        ret[base_version_ndx] = impl
      end

      def impl_index(namespace, module_name, version)
        "#{namespace}:#{module_name}:#{version}"
      end
      BaseVersion = nil

      def choose_namespaces__pick_first_level!(opts = {})
        base_module_refs = nil
        if assembly_instance = opts[:assembly_instance]
          base_module_refs = ret_base_module_refs(assembly_instance)
        end
        # assembly_instance.get_parent.get_service_module.get_component_module_refs
        each_pair do |module_name, els|
          if els.size > 1
            sorted_els = els.sort { |a, b| a.level <=> b.level }
            first_el = sorted_els.first
            first_el_level = first_el.level
            #warning only if first_el does not have level 1 and multiple namesapces
            unless first_el_level == 1
              namespaces = els.map(&:namespace).uniq
              if namespaces.size > 1
                Log.error("Multiple namespaces (#{namespaces.join(',')}) for '#{module_name}'; picking one '#{first_el.namespace}'")
              end
              # calculate right module ref lock based on dependency specified in base module
              if selected_el = find_matching_element_by_parent_module_refs!(first_el, sorted_els, base_module_refs)
                first_el = selected_el
              end
            end
            self[module_name] = [first_el]
          end
        end
        self
      end

      def each_element(&block)
        values.each { |els| els.each { |el| block.call(el) } }
      end

      def ret_base_module_refs(assembly_instance)
        if parent = assembly_instance.get_parent
          if parent_service_module = parent.get_service_module
            parent_service_module.get_component_module_refs(parent[:version])
          end
        end
      end

      def find_matching_element_by_parent_module_refs!(first_el, sorted_els, base_module_refs)
        return unless base_module_refs

        name           = first_el.module_name
        level          = first_el.level
        same_level_els = sorted_els.select { |el| level == el.level }

        return unless same_level_els.size > 1

        component_modules = base_module_refs.component_modules || {}
        if matching_module_ref = component_modules[name] || component_modules[name.to_sym]
          version_info = matching_module_ref[:version_info]
          if matching_by_version = same_level_els.find {|el| (el.version == version_info) || el.version == version_info.to_s }
            matching_by_version
          end
        end
      end
    end
  end
end; end
