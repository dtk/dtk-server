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
  class CommonModule
    class Info::Service
      class Remote < Info::Remote
        # returns true if service info is published
        def publish?
          unless module_branch = get_module_branch?
            return nil # no service info
          end

          repo                 = get_repo_with_branch
          dsl_file_obj         = CommonDSL::Parse.matching_common_module_top_dsl_file_obj?(commom_module_branch)
          parsed_common_module = dsl_file_obj.parse_content(:common_module)

          # this means assemblies part is deleted from module
          return unless parsed_common_module[:assemblies]

          CommonDSL::Parse.set_dsl_version!(commom_module_branch, parsed_common_module)

          args = [project, local, nil, commom_module_branch, parsed_common_module, {}]
          file_path__content_array = CommonModule::Update::Module::Info::Service.new(*args).transform_from_common_module?

          RepoManager.add_files(module_branch, file_path__content_array)
          module_obj.publish_info(module_branch, repo, remote, local, client_rsa_pub_key)

          true
        end

        private
        
        def self.info_type
          Info::Service.info_type
        end

        def module_class
          ServiceModule
        end

        def commom_module_branch
          CommonModule.matching_module_branch?(project, namespace, module_name, version) || fail(Error, "Unexpecetd that CommonModule.matching_module_branch? is nil") 
        end

      end
    end
  end
end
