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
    module ClassMixin
      def find_from_name_with_version?(project, namespace, module_name, version)
        ret = nil
        unless namespace_obj = Namespace.find_by_name?(project.model_handle(:namespace), namespace)
          return ret
        end

        sp_hash = {
          cols: [
            :id,
            :group_id,
            :display_name,
            :namespace_id,
            :namespace,
            :version_info
          ],
          filter: [
            :and,
            [:eq, :project_project_id, project.id],
            [:eq, :namespace_id, namespace_obj.id],
            [:eq, :display_name, module_name]
          ]
        }

        get_objs(project.model_handle(model_type), sp_hash).find{ |mod| (mod[:module_branch]||{})[:version] == version }
      end

      def get_remote_module_info(project, rsa_pub_key, remote_params)
        remote = remote_params.create_remote(project)
        remote_repo_info = Repo::Remote.new(remote).get_remote_module_info?(rsa_pub_key, raise_error: true)
      end
    end
  end
end
