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
    module MatchingTemplatesMixin
      # component refs are augmented with :component_template key which points to
      # associated component template or nil
      # opts can have keys
      #   :raise_if_missing_dependencies
      #   :module_local_params
      #   :donot_set_component_templates
      #   :set_namespace
      #   :force_compute_template_id
      def set_matching_component_template_info?(aug_cmp_refs, opts = {})
        unless aug_cmp_refs.empty?
          # determine which elements of aug_cmp_refs need to be matches
          cmp_types_to_check = determine_component_refs_needing_matches(aug_cmp_refs, force_compute_template_id: opts[:force_compute_template_id])
          set_matching_component_template_info!(aug_cmp_refs, cmp_types_to_check, opts) unless cmp_types_to_check.empty?
        end
        aug_cmp_refs
      end

      private

      # opts can have keys:
      #   :force_compute_template_id
      def determine_component_refs_needing_matches(aug_cmp_refs, opts = {})
        # for each element in aug_cmp_ref, want to set cmp_template_id using following rules
        # 1) if key 'has_override_version' is set
        #    a) if it points to a component template, use this
        #    b) otherwise look it up using given version
        # 2) else look it up and if lookup exists use this as the value to use; element marked required if it does not point to a component template
        # lookup based on matching both version and namespace, if namespace is given
        cmp_types_to_check = {}
        aug_cmp_refs.each do |r|
          unless cmp_type = r[:component_type] || (r[:component_template] || {})[:component_type]
            ref =  ComponentRef.print_form(r)
            ref = (ref ? "(#{ref})" : '')
            fail Error.new("Component ref #{ref} must either point to a component template or have component_type set")
          end
          cmp_template_id = r[:component_template_id]
          if r[:has_override_version]
            unless cmp_template_id
              unless r[:version]
                fail Error.new('Component ref has override-version flag set, but no version')
              end
              (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << { pntr: r, version: r[:version] }
            end
          else
            add_item = true
            if r[:template_id_synched] and not opts[:force_compute_template_id]
              if cmp_template_id.nil?
                Log.error("Unexpected that cmp_template_id is null for (#{r.inspect})")
              else
                add_item = false
              end
            end
            if add_item
              (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << { pntr: r, required: cmp_template_id.nil? }
            end
          end
          r[:template_id_synched] = true #marking each item synchronized
        end

        # shortcut if no locked versions and no required elements
        if component_modules.empty? and not cmp_types_to_check.values.find(&:mapping_required?)
          # TODO: should we instead prune out all those that dont have mapping required
          return {}
        end
        cmp_types_to_check
      end

      # opts can have keys:
      #   :raise_if_missing_dependencies
      #   :module_local_params
      #   :set_namespace
      #   :donot_set_component_templates
      def set_matching_component_template_info!(aug_cmp_refs, cmp_types_to_check, opts = {})
        ret = aug_cmp_refs
        # Lookup up modules mapping
        # mappings will have key for each component type referenced and for each key will return hash with keys :component_template and :version;
        # component_template will be null if no match is found
        mappings = get_component_type_to_template_mappings?(cmp_types_to_check.keys, module_local_params: opts[:module_local_params])

        if opts[:set_namespace]
          ret.each do |cmp_ref|
            cmp_type = cmp_ref[:component_type]
            next unless cmp_types_to_check[cmp_type]
            if cmp_template_match_el = mappings[cmp_type]
              if namespace = cmp_template_match_el.namespace
                cmp_ref[:namespace] = namespace
              end
            end
          end
        end

        cmp_types_to_check.each do |cmp_type, els|
          els.each do |el|
            cmp_template_match_el = mappings[cmp_type]
            if cmp_template = cmp_template_match_el.component_template
              el[:pntr][:component_template_id] = cmp_template.id
              el[:pntr][:component_template] = cmp_template unless opts[:donot_set_component_templates]
            end
          end
        end

        # TODO: DTK-2266: think can delete below
        # update_module_refs_dsl?(mappings, raise_if_missing_dependencies: opts[:raise_if_missing_dependencies])
        ret
      end

      # opts can have keys: 
      #  :module_local_params
      def get_component_type_to_template_mappings?(cmp_types, opts = {})
        ret = {}
        return ret if cmp_types.empty?
        # first put in ret info about component type and version
        ret = cmp_types.inject({}) do |h, cmp_type|
          version = version_string?(cmp_type)
          match_el = Component::Template::MatchElement.new(cmp_type, ModuleBranch.version_field(version))
          if namespace = namespace?(cmp_type)
            match_el.namespace = namespace
          end
          h.merge(cmp_type => match_el)
        end

        # get matching component template info and insert matches into ret
        Component::Template.get_matching_elements(project_idh, ret.values, module_local_params: opts[:module_local_params]).each do |cmp_template|
          ret[cmp_template[:component_type]].component_template = cmp_template
        end
        ret
      end

      # opts can have keys:
      #   :raise_if_missing_dependencies
      def update_module_refs_dsl?(cmp_type_to_template_mappings, opts = {})
        module_name_to_ns = {}
        cmp_type_to_template_mappings.each do |cmp_type, cmp_template_match_el|
          module_name = module_name(cmp_type)
          unless module_name_to_ns[module_name]
            if namespace = (cmp_template_match_el.component_template || {})[:namespace]
              module_name_to_ns[module_name] = namespace
            end
          end
        end
        cmp_module_refs_to_add = []
        module_name_to_ns.each do |cmp_module_name, namespace|
          if component_module_ref = component_module_ref?(cmp_module_name)
            unless component_module_ref.namespace == namespace
              fail Error.new("Unexpected that at this point component_module_ref.namespace (#{component_module_ref.namespace()}) not equal to namespace (#{namespace})")
            end
          else
            new_cmp_moule_ref = {
              module_name: cmp_module_name,
              module_type: 'component',
              namespace_info: namespace
            }
            cmp_module_refs_to_add << new_cmp_moule_ref
          end
        end

        unless cmp_module_refs_to_add.empty?
          if opts[:raise_if_missing_dependencies]
            mapping_refs = cmp_module_refs_to_add.map{ |mr| "#{mr[:namespace_info]}:#{mr[:module_name]}" }
            # need to skip adding of aws:ec2 because we add it after module is installed
            mapping_refs.delete('aws:ec2')
            fail ErrorUsage, "You are using component(s) from following modules which are not added as dependencies: #{mapping_refs.join(', ')}!" unless mapping_refs.empty?
          end
          ModuleRef.update(:add, @parent, cmp_module_refs_to_add)
        end
      end

      def version_string?(component_type)
        if cmp_module_ref = component_types_module_ref?(component_type)
          cmp_module_ref.version_string()
        end
      end

      def namespace?(component_type)
        if cmp_module_ref = component_types_module_ref?(component_type)
          cmp_module_ref.namespace()
        end
      end

      def module_name(component_type)
        Component.module_name(component_type)
      end

      def component_types_module_ref?(component_type)
        component_module_ref?(module_name(component_type))
      end
    end
  end
end
