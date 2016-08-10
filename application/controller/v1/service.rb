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
    class ServiceController < V1::Base
      require_relative('service/get_mixin')
      require_relative('service/post_mixin')
      include GetMixin
      include PostMixin

      helper_v1 :module_ref_helper
      helper_v1 :service_helper
      helper :assembly_helper
      helper :task_helper


      ### TODO: remove or move to GetMixin or PostMixin
      def access_tokens
        service = service_object
        rest_ok_response
      end

      def create_assembly
        service = service_object
        assembly_template_name, service_module_name, module_namespace = get_template_and_service_names_params(service)

        if assembly_template_name.nil? || service_module_name.nil?
          fail ErrorUsage.new('SERVICE-NAME/ASSEMBLY-NAME cannot be determined and must be explicitly given')
        end

        project = get_default_project
        opts = { mode: :create, local_clone_dir_exists: false }

        if namespace = request_params(:namespace)
          opts.merge!(namespace: namespace)
        elsif request_params(:use_module_namespace)
          opts.merge!(namespace: module_namespace)
        end

        if description = request_params(:description)
          opts.merge!(description: description)
        end

        service_module = Assembly::Template.create_or_update_from_instance(project, service, service_module_name, assembly_template_name, opts)
        rest_ok_response service_module.ret_clone_update_info
      end

      def tasks
        service = service_object
        rest_ok_response service.info_about(:tasks)
      end

    end
  end
end
