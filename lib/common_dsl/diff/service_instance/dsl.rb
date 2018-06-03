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
module DTK; module CommonDSL
  class Diff
    module ServiceInstance
      module DSL
        # Parses and processes any service instance dsl changes; if dsl updated then updates diff_result or raises error
        def self.process_service_instance_dsl_changes(diff_result, service_instance, module_branch, impacted_files)
          # TODO: DTK-2738:  service_instance.get_dsl_locations will have path of any nested dsl file that is in an import
          #  statement from service_instance_top_dsl_file or any nested dsl file that is recursively broght in throgh imports
          #  This will be used in Parse.matching_dsl_file_obj?; it will return non nil if top or any nested
          #  dsl files are impacted
          if dsl_file_obj = Parse.matching_dsl_file_obj?(:service_instance, module_branch, impacted_files: impacted_files)
            service_instance_parse = dsl_file_obj.parse_content(:service_instance)
            service_instance_gen   = Generate::ServiceInstance.generate_canonical_form(service_instance, module_branch)

            # process dependencies first
            if cmp_modules_with_namespaces = ret_cmp_modules_with_namespaces(service_instance_parse[:dependent_modules] || {})
              # component_module_refs = ModuleRefs.get_component_module_refs(module_branch)
              component_module_refs = service_instance.assembly_instance.component_module_refs
              component_module_refs.update if component_module_refs.update_object_if_needed!(cmp_modules_with_namespaces)
            end

            # compute base diffs
            if base_diffs = compute_base_diffs?(service_instance, service_instance_parse, service_instance_gen, impacted_files: impacted_files)
              # collate the diffs
              if collated_diffs = base_diffs.collate
                dsl_version = service_instance_gen.req(:DSLVersion)
                # TODO: DTK-2665: look at moving setting semantic_diffs because process_diffs can remove items
                #  alternatively have items removed (e.g., create workflow rejected) in compute_base_diffs
                diff_result.semantic_diffs = collated_diffs.serialize(dsl_version)
                process_diffs(diff_result, collated_diffs, module_branch, service_instance_gen, dependent_modules: service_instance_parse[:dependent_modules], service_instance: service_instance, impacted_files: impacted_files, service_instance_parse: service_instance_parse)
              end
            end
          end
        end

        private

        # opts can have keys:
        #   :impacted_files
        def self.compute_base_diffs?(service_instance, service_instance_parse, service_instance_gen, opts = {})
          assembly_gen   = service_instance_gen.req(:Assembly)
          assembly_parse = service_instance_parse # assembly parse and service_instance parse are identical
          assembly_gen.diff?(assembly_parse, QualifiedKey.new, service_instance: service_instance, impacted_files: opts[:impacted_files])
        end
        
        def self.update_semantic_diff(diff_result, service_instance, module_branch, impacted_files, service_instance_parse)
          if dsl_file_obj = Parse.matching_dsl_file_obj?(:service_instance, module_branch, impacted_files: impacted_files)
            service_instance_gen = Generate::ServiceInstance.generate_canonical_form(service_instance, module_branch)
            if new_diffs = compute_base_diffs?(service_instance, service_instance_parse, service_instance_gen, impacted_files: impacted_files)
              update_collated = new_diffs.collate
              diffs = update_collated.instance_variable_get(:@diffs)
              SerializedHash.create(dsl_version: service_instance_gen.req(:DSLVersion)) do |serialized_hash|
                CommonDSL::Diff::Collated::Sort::ForSerialize.sort_keys(diffs.keys).each do |collate_key|
                  diffs_of_same_type = diffs[collate_key]
                  diff_result.semantic_diffs.add_collate_level_elements?(collate_key, diffs_of_same_type)
                end
              end

              #TODO: Find better solution to update semantic_diffs
              unless diff_result.semantic_diffs["COMPONENT_LINKS_ADDED"].nil? && diff_result.semantic_diffs["COMPONENTS_DELETED"].nil?
                diff_result.semantic_diffs["COMPONENT_LINKS_DELETED"] = diff_result.semantic_diffs["COMPONENT_LINKS_ADDED"]
                diff_result.semantic_diffs.delete("COMPONENT_LINKS_ADDED")
              end

              return if diff_result.semantic_diffs["WORKFLOWS_MODIFIED"].nil? 
              diff_result.semantic_diffs["WORKFLOWS_MODIFIED"].each do |v|
                v.each do |k|
                  k[1]["CURRENT_VAL"], k[1]["NEW_VAL"] = k[1]["NEW_VAL"], k[1]["CURRENT_VAL"]
                end
              end
            end
          end
        end

        def self.process_diffs(diff_result, collated_diffs, module_branch, service_instance_gen, opts = {})
          DiffErrors.process_diffs_error_handling(diff_result, service_instance_gen) do
            Model.Transaction do
              collated_diffs.process(diff_result, { service_instance_branch: module_branch }.merge(opts))
              DiffErrors.raise_if_any_errors(diff_result)
              Aux.stop_for_testing?(:push_diff) # for debug

              # items_to_update are things that need to be updated in repo from what at this point are in object model
              items_to_update = diff_result.items_to_update
              if diff_result.items_to_update.include?(:workflow)
                service_instance       = opts[:service_instance]
                impacted_files         = opts[:impacted_files]
                service_instance_parse = opts[:service_instance_parse]
                semantic_update =  update_semantic_diff(diff_result, service_instance, module_branch, impacted_files, service_instance_parse)
              end
              # items_to_update are things that need to be updated in repo from what at this point are in object model
              unless items_to_update.empty?
                # update dtk.service.yaml with data from object model
                Generate::ServiceInstance.generate_dsl_and_push!(opts[:service_instance], module_branch)
                diff_result.repo_updated = true # means repo updated by server
              end
            end
          end
        end

        def self.cmp_modules_with_namespaces_hash(module_name_input, namespace_name_input, version_input)
          {
            display_name: module_name_input,
            namespace_name: namespace_name_input,
            version_info: version_input
          }
        end

        def self.ret_cmp_modules_with_namespaces(parsed_dependent_modules, opts = {})
          cmp_modules_with_namespaces = (parsed_dependent_modules || {}).map do |namespace_name, version|
            module_namespace, module_name = namespace_name.split('/')
            cmp_modules_with_namespaces_hash(module_name, module_namespace, version)
          end.compact
        end

      end
    end
  end
end; end
