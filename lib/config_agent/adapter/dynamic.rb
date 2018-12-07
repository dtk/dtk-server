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
      require_relative('dynamic/execution_environment')
      require_relative('dynamic/interpret_results')

      include DynamicAttributes::Mixin
      include ErrorResults::Mixin
      include InterpretResults::Mixin

      def ret_msg_content(task_info, opts = {})
        breakpoint            = task_info[:breakpoint]
        debug_port_request    = (opts[:debug_port_request] ? true : nil)
        assembly_instance     = opts[:assembly]
        component_action      = task_info[:component_actions].first
        method_name           = component_action.method_name? || 'create'
        component             = component_action.component
        node                  = task_info[:node]
        component_template    = component_template(component)
        action_def            = ActionDef.get_matching_action_def_params?(component_template, method_name)
        service_instance_name = assembly_instance.display_name
        failure_attempts      = nil
        failure_sleep         = nil
        task_params           = task_info[:task_params]

        ConfigAgent.raise_error_on_illegal_task_params(component_action.attributes, action_def, task_params) if task_params && action_def.key?(:parameter_defs)

        if task_info.is_a?(Hash)
          task_info_retry = task_info[:retry] || {}
          if task_info_retry.is_a?(Hash)
            failure_attempts      = task_info_retry[:attempts]
            failure_sleep         = task_info_retry[:retry]
          else
            task_info[:attempts]  = task_info[:attempts].to_i
            task_info[:retry]     = task_info[:retry].to_i
            failure_attempts      = task_info[:attempts] if task_info[:attempts]!= 0
            failure_sleep         = task_info[:retry] if task_info[:retry] != 0
          end
        end

        dynamic_provider = ActionDef::DynamicProvider.matching_dynamic_provider(component_template, method_name, assembly_instance)
        dynamic_provider.raise_error_if_not_valid

        nested_module_info = get_base_and_dependent_modules(assembly_instance)

        system_values = {}
        if base_component_repo = base_component_repo?(nested_module_info, assembly_instance)
          system_values_to_add = {
            base_component_repo: AttributeRequestForm::Info.new(base_component_repo, 'hash', false),
            base_module_name: AttributeRequestForm::Info.new(base_module_name(assembly_instance), 'string', true)
          }
          system_values.merge!(system_values_to_add)
        end

        execution_environment = ExecutionEnvironment.execution_environment(dynamic_provider, node, breakpoint: breakpoint)

        provider_attributes = AttributeRequestForm.transform_attribute(dynamic_provider.entrypoint_attribute)
        instance_attributes = AttributeRequestForm.component_attribute_values(component_action, assembly_instance, system_values)

        #format parameters sent from command line
        if task_params && !task_params.empty?
          task_params = task_params.inject({}) { |h, (k, v)| h[k] = {:value => v, :datatype => 'string', :hidden => 'false'}; h }
          instance_attributes = instance_attributes.merge(task_params) if task_params
        end

        msg = {
          protocol_version: ArbiterInfo::PROTOCOL_VERSION,
          provider_type: dynamic_provider.type,
          service_instance: service_instance_name,
          component: component_request_form(component_action),
          attributes: { 
            provider: provider_attributes,
            instance: instance_attributes,
          },
          modules: nested_module_info,
          execution_environment: execution_environment,
          debug_port_request: debug_port_request,
          failure_attempts: failure_attempts,
          failure_sleep: failure_sleep
        }
        unless debug_port_request
          msg.merge!(breakpoint: breakpoint, debug_port_received: $port_number)
        end

        Aux.convert_keys_to_symbols_recursive(msg)
      end

      def type
        :dynamic
      end
      
      private
      
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

      def base_module_name(assembly_instance)
        if service_module = service_module?(assembly_instance)
          service_module.display_name
        else
          Log.error("Unexpected that service_module?(assembly_instance) is nil")
          nil
        end
      end

      def base_component_repo?(nested_module_info, assembly_instance)
        if service_module = service_module?(assembly_instance)
          if repo_info = nested_module_info[service_module.display_name]
            { 
              repo_url: RepoManager.repo_url(repo_info[:repo]),
              sha: repo_info[:sha]
            }
          end
        end
      end
      
      def service_module?(assembly_instance)
        if ancestor_id = assembly_instance.get_field?(:ancestor_id) 
          assembly_template = assembly_instance.model_handle(:assembly_template).createIDH(id:  ancestor_id).create_object
          assembly_template.get_service_module
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
