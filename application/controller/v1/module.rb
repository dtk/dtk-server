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
  module V1
    class ModuleController < V1::Base
      helper :module_helper
      # helper :remotes_helper

      LIST_ASSEMBLIES_DATATYPE = :assembly_template_with_module

      def list_assemblies
        project = get_default_project
        rest_ok_response CommonModule.list_assembly_templates(get_default_project), datatype: LIST_ASSEMBLIES_DATATYPE
      end

      def exists
        namespace, module_name = required_request_params(:namespace, :module_name)
        version = request_params(:version)||'master'
        rest_ok_response CommonModule.exists(get_default_project, namespace, module_name, version)
      end

      def install_component_module
        rest_ok_response install_from_dtkn_helper(:component_module)
      end
    end
  end
end
