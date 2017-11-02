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
  module V1ModuleHelper
    def ret_context_assembly_instances(param = :context_service_names)
      # TODO: DTK-3296: when patch regression tests put in below for uncommented out
      # if context_service_names = ret_request_params(param)
      target_service_name = ret_request_params(:target_service)
      if context_service_names = ret_request_params(param) || (target_service_name && [target_service_name])
         context_service_names.map do |service_name| 
          assembly_id = resolve_id_from_name_or_id(service_name, ::DTK::Assembly::Instance)
          create_assembly_instance_object(assembly_id)
        end
      else
        [ret_default_context_assembly_instance]
      end
    end

    def ret_default_context_assembly_instance
      ::DTK::Service::Target.create_from_target(default_target).assembly_instance
    end

    def remote_params_dtkn_service_and_component_info(namespace, module_name, version = nil)
      ::DTK::ModuleBranch::Location::RemoteParams::DTKNCatalog.new(
          module_type: ::DTK::CommonModule.combined_module_type,
          module_name: module_name,
          version: version,
          namespace: namespace,
          remote_repo_base: ::DTK::Repo::Remote.default_remote_repo_base
     )
    end

    def ret_detail_to_include
      if detail = ret_request_params(:detail_to_include)
        if detail.kind_of?(Array)
          # nothing needed
        else
          # it will be string
          begin
            detail = JSON.parse(detail)
          rescue
            fail ErrorUsage, "Param 'detail_to_include' is ill-formed"
          end
        end
        detail.map(&:to_sym)
      end
    end
  end
end
