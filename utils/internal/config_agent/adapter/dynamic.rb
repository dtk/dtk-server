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
      require_relative('dynamic/dynamic_attributes')
      require_relative('dynamic/error_results')

      include DynamicAttributes::Mixin
      include ErrorResults::Mixin

      def ret_msg_content(config_node, opts = {})
        assembly_instance     = opts[:assembly]
        component_action      = config_node[:component_actions].first
        method_name           = component_action.method_name? || 'create'
        component             = component_action[:component]
        component_template    = component_template(component)

        dynamic_provider = ActionDef::DynamicProvider.matching_dynamic_provider(component_template, method_name, assembly_instance)
        dynamic_provider.raise_error_if_not_valid
        
        docker_file = dynamic_provider.docker_file?
        
        execution_environment =
          if docker_file
            { type: ExecutionEnvironment::EPHEMERAL_CONTAINER, docker_file: docker_file }
          else
            { type: ExecutionEnvironment::NATIVE }
          end
        
        msg = {
          provider_type: dynamic_provider.type,
          attributes: { 
            provider: { 'entrypoint' =>  dynamic_provider.entrypoint },
            instance: component_attribute_values(component_action)
          },
          modules: get_base_and_dependent_modules(component, assembly_instance),
          component_name: component_action.component_module_name,
          execution_environment: execution_environment 
        }          
        # TODO: DTK-2847: once sending attributes with meta data can display attributes below after running santize method on them
        # hack to take out attributes until
        Log.info_pp [:message_sent_to_dynamic_provider, msg.merge(attributes: '[ATTRIBUTES]')]
        
        msg
      end

      module ExecutionEnvironment
        EPHEMERAL_CONTAINER = 'ephemeral_container'
        NATIVE = 'native'
      end
      
      def type
        :dynamic
      end
      
      private

      def component_attribute_values(component_action)
        component_action.attributes.inject({}) do |h, attr|
          # prune dynamic attributes that are not also inputs
          (attr[:dynamic] and !attr[:dynamic_input]) ? h : h.merge(attr.display_name => attr[:attribute_value])
        end
      end

      # TODO: DTK-2848: use component to prune list
      def get_base_and_dependent_modules(component, assembly_instance)
        ModuleRefs::Lock.get_corresponding_aug_module_branches(assembly_instance).inject({}) do |h, aug_module_branch|
          module_info = {
            repo: aug_module_branch.repo.display_name,
            branch: aug_module_branch.branch_name,
          }
          module_info.merge!(sha: aug_module_branch.current_sha) if aug_module_branch.frozen
          h.merge(aug_module_branch.module_name => module_info)
        end
      end
      
      def component_template(component)
        component.id_handle(id: component[:ancestor_id]).create_object
      end
      
      # TODO: deprerate; used for testing
      # MSG_LOCATION = '/host_volume/ruby_provider_test.yaml'
      # def get_stubbed_message
      #  file_content = File.open(MSG_LOCATION).read
      #  YAML.load(file_content)
      # end
      
    end
  end
end; end

