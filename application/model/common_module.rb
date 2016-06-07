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
  module CommonModule
    # Mixins must go first
    require_relative('common_module/mixin')
    require_relative('common_module/class_mixin')

    extend  CommonModule::ClassMixin
    include CommonModule::Mixin

    require_relative('common_module/dsl')
    require_relative('common_module/service')
    require_relative('common_module/component')

    def self.list_assembly_templates(project)
      Service::Template.list_assembly_templates(project)
    end

    def self.get_module_dependencies(project, rsa_pub_key, remote_params)
      Component::Template.get_module_dependencies(project, rsa_pub_key, remote_params)
    end

    def self.install_module(module_type, project, local_params, remote_params, dtk_client_pub_key)
      case module_type
        when :component_module
          Component::Template.install_module(project, local_params, remote_params, dtk_client_pub_key)
        when :service_module
          Service::Template.install_module(project, local_params, remote_params, dtk_client_pub_key)
        else
          fail ErrorUsage.new("Invalid module type #{module_type}!")
        end
    end
  end
end
