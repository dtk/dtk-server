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
          repo = get_repo_with_branch

          # DTK-2806: put in code that uses transform to from contenet in common module to repo/branch captured by
          # module_branch, repo; this service module will initially have no info in it, it can be place where we put
          # Need to check if this can be called after the content is updated. Probably only for master version
          pp [:service_publish_info, module_branch, repo]

          # The source info is on the repo handing off the common module branch
          pp [:commom_module_branch, commom_module_branch]
          dsl_file_obj = CommonDSL::Parse.matching_common_module_top_dsl_file_obj?(commom_module_branch)
          parsed_common_module = dsl_file_obj.parse_content(:common_module)
          CommonDSL::Parse.set_dsl_version!(commom_module_branch, parsed_common_module)

          args = [project, local, nil, commom_module_branch, parsed_common_module, {}]
          file_path__content_array = CommonModule::Update::Module::Info::Service.new(*args).transform_from_common_module?
          # transform.input_paths.each { |path| RepoManager.delete_file?(path, {no_commit: true}, @aug_component_module_branch) }
          RepoManager.add_files(module_branch, file_path__content_array)
          
          # Need to check below doing right thing; right now just pushing empty content since service module barnch is empty

          response = module_obj.publish_info(module_branch, repo, remote, local, client_rsa_pub_key)
          #  DTK-2806: need to check response for errors otr see if code throws errors
          pp [:publish_info_response, response]
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
