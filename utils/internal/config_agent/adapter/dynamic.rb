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

        provider_attributes = attribute_form_for_request(dynamic_provider.entrypoint_attribute)
        instance_attributes = component_attribute_values_for_request(component_action)

        msg = {
          protocol_version: ARBITER_REQUEST_PROTOCOL_VERSION,
          provider_type: dynamic_provider.type,
          attributes: { 
            provider: provider_attributes,
            instance: instance_attributes,
          },
          modules: get_base_and_dependent_modules(component, assembly_instance),
          component_name: component_action.component_module_name,
          execution_environment: execution_environment 
        }          
        Log.info_pp [:message_sent_to_dynamic_provider, Sanitize.sanitize_message(msg)]

        # TODO: DTK-2847: when switch over on arbiter side remove this line and remove the module HackForDTK2847
        msg = HackForDTK2847.convert_message(msg)

        msg
      end
      ARBITER_REQUEST_PROTOCOL_VERSION = 1

      module ExecutionEnvironment
        EPHEMERAL_CONTAINER = 'ephemeral_container'
        NATIVE = 'native'
      end
      
      def type
        :dynamic
      end
      
      private

      def attribute_form_for_request(attribute)
        attribute_info = {
          value: attribute[:attribute_value],
          datatype: attribute[:data_type],
          hidden: attribute[:hidden]
        }
        { attribute.display_name => attribute_info }
      end

      def component_attribute_values_for_request(component_action)
        component_action.attributes.inject({}) do |h, attr|
          # prune dynamic attributes that are not also inputs
          (attr[:dynamic] and !attr[:dynamic_input]) ? h : h.merge(attribute_form_for_request(attr))
        end
      end

      def sanitized_attribute_values(attribute)
        
      end

      # TODO: DTK-2848: use component to prune list
      def get_base_and_dependent_modules(component, assembly_instance)
        ModuleRefs::Lock.get_corresponding_aug_module_branches(assembly_instance).inject({}) do |h, aug_module_branch|
          module_info = {
            repo: aug_module_branch.repo.display_name,
            branch: aug_module_branch.branch_name,
          }
          # need sha if points to base module otherwise it is an assembly_module_version
          module_info.merge!(sha: aug_module_branch.current_sha) unless is_assembly_module_version?(aug_module_branch)
          h.merge(aug_module_branch.module_name => module_info)
        end
      end

      def is_assembly_module_version?(aug_module_branch)
        ModuleVersion.assembly_module_version?(aug_module_branch.version)
      end

      def component_template(component)
        component.id_handle(id: component[:ancestor_id]).create_object
      end

      module Sanitize
        def self.sanitize_message(msg)
          sanitized_attributes = msg[:attributes].inject({}) do |h, (type, attributes_hash)| 
            h.merge(type => attributes_hash.inject({}) { |h, (name, info)| h.merge(name => sanitize_attribute(name, info)) })
          end
          msg.merge(attributes: sanitized_attributes)
        end

        private
        
        HIDDEN_VALUE = '***'
        def self.sanitize_attribute(name, attr_info)
          (attr_info[:hidden] || ['password', 'secret'].any? { |pattern| name.downcase.include? pattern }) ? attr_info.merge(value: HIDDEN_VALUE) : attr_info 
        end
      end

      module HackForDTK2847
        def self.convert_message(msg)
          converted_attributes = msg[:attributes].inject({}) do |h, (type, attributes_hash)|
            h.merge(type => attributes_hash.inject({}) { |h, (name, info)| h.merge(name => info[:value]) })
          end
          msg.merge(attributes: converted_attributes)
        end
      end
      
    end
  end
end; end

