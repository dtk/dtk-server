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
      def matching_module_with_module_branch?(project, namespace, module_name, version)
        ret = nil
        return ret unless namespace_obj = Namespace.find_by_name?(project.model_handle(:namespace), namespace)
        sp_hash = {
          cols: [:id, :group_id, :display_name, :namespace_id, :namespace, :version_info],
          filter: [:and, [:eq, :project_project_id, project.id], [:eq, :namespace_id, namespace_obj.id], [:eq, :display_name, module_name]]
        }
        get_objs(project.model_handle(model_type), sp_hash).find{ |mod| (mod[:module_branch]||{})[:version] == version }
      end

      NS_MOD_DELIM_IN_REF = ':'
      def find_from_name?(model_handle, namespace, module_name)
        ref = "#{namespace}#{NS_MOD_DELIM_IN_REF}#{module_name}"
        get_obj(model_handle, sp_filter(:eq, :ref, ref))
      end

      def find_from_id?(model_handle, module_id)
        get_obj(model_handle, sp_filter(:eq, :id, module_id))
      end

    end
  end
end
