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
  module CommonDSL
    module Generate
      module ServiceInstance
        def self.generate_canonical_form(service_instance, service_module_branch)
          ContentInput.generate_for_service_instance(service_instance, service_module_branch)
        end
        
        def self.generate_dsl_and_push!(service_instance, service_module_branch)
          add_service_dsl_files(service_instance, service_module_branch)
          RepoManager.push_changes(service_module_branch)
          service_module_branch.update_current_sha_from_repo! # updates object model to indicate sha read in
          service_module_branch
        end
        
        def self.add_service_dsl_files(service_instance, service_module_branch)
          file_path__content_array = generate_service_dsl_contet(service_instance, service_module_branch)
          DirectoryGenerator.add_files(service_module_branch, file_path__content_array, donot_push_changes: true)
        end

        def self.generate_service_dsl_contet(service_instance, service_module_branch)
          # content_input is a dsl version independent canonical form that has all content needed to
          # content_input = generate_canonical_form(service_instance, service_module_branch)

          # content_input = ObjectLogic::Assembly::Attribute.generate_content_input?(:assembly, (service_instance.get_assembly_level_attributes || {}))
          content_input = ObjectLogic::Assembly::Attribute.generate_content_input?(:assembly, service_instance.get_attributes_all_levels)

          dsl_version   = service_module_branch.dsl_version
          top_file_path = FileType::ServiceInstance::DSLFile::Top.canonical_path
          check_for_assembly_wide(content_input)
          return content_input
          FileGenerator.generate_yaml_file_path__content_array(:service_instance, top_file_path, content_input, dsl_version)
        end

        private
        
        def self.check_for_assembly_wide(content_input)
          if assembly = content_input[:asssembly]
            (assembly[:workflows]||{}).each_pair do |k, v|
              (v[:subtasks]||{}).each do |subtask|
                subtask.delete(:node) if subtask.has_key?(:node) && subtask[:node].eql?('assembly_wide')
              end
            end
          end
        end
      end
    end
  end
end

