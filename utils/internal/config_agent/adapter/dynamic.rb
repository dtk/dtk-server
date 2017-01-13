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
module DTK; class ConfigAgent
  module Adapter
    class Dynamic < ConfigAgent
      def ret_msg_content(config_node, opts = {})
        assembly_instance     = opts[:assembly]
        component_action      = config_node[:component_actions].first
        method_name           = component_action.method_name? || 'create'
        component             = component_action[:component]
        component_template    = component_template(component)

        dynamic_provider = ActionDef::DynamicProvider.matching_dynamic_provider(component_template, method_name, assembly_instance)
        dynamic_provider.raise_error_if_not_valid

        docker_file = dynamic_provider.docker_file?

        msg = get_stubbed_message
        msg.merge!(
          modules: get_base_and_dependent_modules(component, assembly_instance),
          component_name: component_action.component_module_name
        )
        if docker_file
          pp :docker_file
          STDOUT << docker_file
          pp 'using docker file from provider'
          msg[:execution_environment] = { type: EPHEMERAL_CONTAINER_TYPE, docker_file: docker_file }
        end

        pp [:msg, msg]

        msg

      end

      EPHEMERAL_CONTAINER_TYPE = 'ephemeral_container'

      def type
        :dynamic
      end
      
      private

      def get_base_and_dependent_modules(component, assembly_instance)
        ComponentModule::VersionContextInfo.get_in_hash_form([component], assembly_instance).inject({}) do |h, r|
          h.merge(r[:implementation] => Aux.hash_subset(r, [:repo, :branch, :sha]))
        end
      end
      
      def component_template(component)
        component.id_handle(id: component[:ancestor_id]).create_object
      end

      MSG_LOCATION = '/host_volume/ruby_provider_test.yaml'
      def get_stubbed_message
        file_content = File.open(MSG_LOCATION).read
        YAML.load(file_content)
      end

    end
  end
end; end

