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
module Ramaze::Helper
  module V1ModuleRefHelper
    def ret_service_module
      module_id, module_name, namespace = request_params(:module_id, :module_name, :namespace)
      unless module_id or (module_name and namespace)
        raise_error_usage("Either 'module_id' or 'module_name and namespace' must be given")
      end
      if module_id
        module_id = Integer(module_id) rescue raise_error_usage("Ill-formed module id term '#{module_id}'")
        ::DTK::CommonModule::Service.find_from_id?(model_handle(:service_module), module_id) ||
          raise_error_usage("No module with id '#{module_id}' exists")
      else
        ::DTK::CommonModule::Service.find_from_name?(model_handle(:service_module),  namespace, module_name) ||
          raise_error_usage("The module '#{namespace}/#{module_name}' does not exist")
      end
    end
  end
end
