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
      require_relative('dynamic/attribute_request_form')

      include DynamicAttributes::Mixin
      include ErrorResults::Mixin

      def ret_msg_content(task_info, opts = {})
        assembly_instance     = opts[:assembly]
        component_action      = task_info[:component_actions].first
        method_name           = component_action.method_name? || 'create'
        component             = component_action.component
        component_template    = component_template(component)
        service_instance_name = assembly_instance.display_name
        dynamic_provider = ActionDef::DynamicProvider.matching_dynamic_provider(component_template, method_name, assembly_instance)
        dynamic_provider.raise_error_if_not_valid
        breakpoint  = task_info[:breakpoint]

        debug_port_request = true if opts[:debug_port_request]
        execution_environment = ExecutionEnvironment.execution_environment(dynamic_provider, component, opts = {breakpoint: breakpoint, assembly_instance: assembly_instance})
        provider_attributes = AttributeRequestForm.transform_attribute(dynamic_provider.entrypoint_attribute)
        instance_attributes = AttributeRequestForm.component_attribute_values(component_action, assembly_instance)

        if debug_port_request
          msg = {
          protocol_version: ARBITER_REQUEST_PROTOCOL_VERSION,
          provider_type: dynamic_provider.type,
          service_instance: service_instance_name,
          component: component_request_form(component_action),
          attributes: { 
            provider: provider_attributes,
            instance: instance_attributes,
          },
          modules: get_base_and_dependent_modules(component, assembly_instance),
          execution_environment: execution_environment,
            debug_port_request: debug_port_request
          }
          return msg
        end

        msg = {
          protocol_version: ARBITER_REQUEST_PROTOCOL_VERSION,
          provider_type: dynamic_provider.type,
          service_instance: service_instance_name,
          component: component_request_form(component_action),
          attributes: { 
            provider: provider_attributes,
            instance: instance_attributes,
          },
          modules: get_base_and_dependent_modules(component, assembly_instance),
          execution_environment: execution_environment,
          breakpoint: breakpoint,
          debug_port_request: opts[:debug_port_request],
          debug_port_received: $port_number
        }           
        msg
      end
      ARBITER_REQUEST_PROTOCOL_VERSION = 1
      
      def type
        :dynamic
      end
      
      private
      
      # TODO: DTK-2848: use component to prune list
      def get_base_and_dependent_modules(component, assembly_instance)
        ModuleRefs::Lock.get_corresponding_aug_module_branches(assembly_instance).inject({}) do |h, aug_module_branch|
          module_info = {
            repo: aug_module_branch.repo.display_name,
            branch: aug_module_branch.branch_name,
            sha: aug_module_branch.current_sha,
            frozen: !is_assembly_module_version?(aug_module_branch)
          }
          h.merge(aug_module_branch.module_name => module_info)
        end
      end
      
      def is_assembly_module_version?(aug_module_branch)
        ModuleVersion.assembly_module_version?(aug_module_branch.version)
      end
      
      def component_template(component)
        component.id_handle(id: component[:ancestor_id]).create_object
      end

      FULL_MODULE_NAME_DELIM = ':'
      # returns hash with keys :namespace, :module_name, Ltype, :version, :title (optional)
      def component_request_form(component_action)
        module_name_with_ns = component_action.component_module_name
        namespace, module_name = module_name_with_ns.split(FULL_MODULE_NAME_DELIM)
        Aux.hash_subset(component_action[:component].print_form_hash, [:type, :version, :title]).merge(namespace: namespace, module_name: module_name)
      end

      module ExecutionEnvironment
        EPHEMERAL_CONTAINER = 'ephemeral_container'
        NATIVE = 'native'
        def self.execution_environment(dynamic_provider, component, opts = {})
          update_dynamic_provider_attributes(dynamic_provider, opts) if opts[:breakpoint]
          if component.get_node.is_assembly_wide_node?            
            docker_file = dynamic_provider.docker_file? || fail(Error, "Unexpected that 'dynamic_provider.docker_file?' is nil")
            { type: EPHEMERAL_CONTAINER, docker_file: docker_file }
          else
            bash = dynamic_provider.bash?  || fail(Error, "Unexpected that 'dynamic_provider.bash?' is nil")
            { type: NATIVE, bash: bash }
          end
        end

        def self.update_dynamic_provider_attributes(dynamic_provider, opts)
          dynamic_provider.provider_attributes.each do |attr|
            if attr[:display_name].eql?("gems") && !attr[:attribute_value].is_a?(Array)
              attr[:attribute_value] << 'byebug' unless attr[:attribute_value].nil? || attr[:attribute_value].include?('byebug') 
            end
          end
        end  
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

    end
  end
end; end