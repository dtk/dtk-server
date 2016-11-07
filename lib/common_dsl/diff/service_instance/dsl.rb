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
        #Parses and processes any service instance dsl changes; if dsl updated then updates diff_result or raises error
        def self.process_service_instance_dsl_changes(diff_result, service_instance, module_branch, impacted_files)
          if dsl_file_obj = Parse.matching_service_instance_top_dsl_file_obj?(module_branch, impacted_files: impacted_files)
            service_instance_parse = dsl_file_obj.parse_content(:service_instance)
            service_instance_gen   = Generate::ServiceInstance.generate_canonical_form(service_instance, module_branch)
            
            # compute base diffs
            if base_diffs = compute_base_diffs?(service_instance, service_instance_parse, service_instance_gen)
              # collate the diffs
              if collated_diffs = base_diffs.collate
                dsl_version = service_instance_gen.req(:DSLVersion)
                # TODO: DTK-2665: look at moving setting semantic_diffs because process_diffs can remove items
                #  alternatively have items removed (e.g., create workflow rejected) in compute_base_diffs
                diff_result.semantic_diffs = collated_diffs.serialize(dsl_version)
                process_diffs(diff_result, collated_diffs, module_branch, service_instance_gen, dependent_modules: service_instance_parse[:dependent_modules], service_instance: service_instance)
              end
            end
          end
        end

        def self.compute_base_diffs?(service_instance, service_instance_parse, service_instance_gen)
          assembly_gen   = service_instance_gen.req(:Assembly)
          assembly_parse = service_instance_parse # assembly parse and service_instance parse are identical
          assembly_gen.diff?(assembly_parse, QualifiedKey.new, service_instance: service_instance)
        end
        
        def self.process_diffs(diff_result, collated_diffs, module_branch, service_instance_gen, opts = {})
          DiffErrors.process_diffs_error_handling(diff_result, service_instance_gen) do
            Model.Transaction do
              collated_diffs.process(diff_result, opts)
              DiffErrors.raise_if_any_errors(diff_result)
              Aux.stop_for_testing?(:push_diff) # for debug
              
              # items_to_update are things that need to be updated in repo from what at this point are in object model
              items_to_update = diff_result.items_to_update
              unless items_to_update.empty?
                # Treat updates to repo from object model as transaction that rolls back git repo to what client set it as
                # If error,  RepoUpdate.Transaction will throw error
                RepoUpdate.Transaction module_branch do
                  # update dtk.service.yaml with data from object model
                  Generate::ServiceInstance.generate_dsl(opts[:service_instance], module_branch)
                  diff_result.repo_updated = true # means repo updated by server
                  # TODO: DTK-2680: remove after finishing testing
                  # raise 'here'
                end
              end
            end
          end
        end

      end
    end
  end
end; end
