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
    ModuleRef = Struct.new(:namespace, :module_name)
    
    def service_module
      module_id, module_name, namespace = request_params(:module_id, :module_name, :namespace)
      unless module_id or (module_name and namespace)
        raise ::DTK::ErrorUsage, "Either 'module_id' or 'module_name and namespace' must be given"
      end
    end
  end
end
=begin
      service_module_id = nil

      unless service_module_id = ret_request_params(:service_module_id)
        if ret_request_params(:service_module_name)
          service_module_id = create_obj(:service_module_name, ServiceModule).id
        end
      end

      # Special case to support Jenikins CLI orders, since we are not using shell we do not have access
      # to element IDs. This "workaround" helps with that.
      if service_module_id
        # this is name of assembly template
        assembly_id        = ret_request_params(:assembly_id)
        version            = ret_request_params(:version)
        service_module     = ServiceModule.find(model_handle(:service_module), service_module_id)

        raise ErrorUsage.new("Unable to find service module for specified parameters: '#{service_module_id}'") unless service_module

        # if we do not specify version use latest
        version = compute_latest_version(service_module) unless version

        module_name        = ret_request_params(:service_module_name)
        assembly_version   = (version.nil? || version.eql?('base')) ? 'master' : version
        assembly_templates = service_module.get_assembly_templates().select { |template| (template[:display_name].eql?(assembly_id) || template[:id] == assembly_id.to_i) }
        assembly_template  = assembly_templates.find{ |template| template[:version] == assembly_version }
        fail ErrorUsage, "We are not able to find assembly '#{assembly_id}' for service module '#{module_name}'" unless assembly_template
      else
        assembly_template = ret_assembly_template_object()
      end
    end
  end
end
=end
