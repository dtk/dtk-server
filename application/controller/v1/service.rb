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
    class ServiceController < AuthController

      helper :assembly_helper
      helper :task_helper

      def create
        target_id = ret_request_param_id_optional(:target_id, Target::Instance)
        target = target_with_default(target_id)

        service_module_obj = create_obj(:service_module_name, ServiceModule)

        # Special case to support Jenikins CLI orders, since we are not using shell we do not have access
        # to element IDs. This "workaround" helps with that.
        if service_module_id = service_module_obj.id
          # this is name of assembly template
          assembly_id = ret_request_params(:assembly_name)
          service_module = ServiceModule.find(model_handle(:service_module), service_module_id)
          assembly_template = service_module.get_assembly_templates().find { |template| template[:display_name].eql?(assembly_id) || template[:id] == assembly_id.to_i }
          fail ErrorUsage, "We are not able to find assembly '#{assembly_id}' for service module '#{service_module_id}'" unless assembly_template
        else
          assembly_template = ret_assembly_template_object()
        end

        opts = {}
        if assembly_name = ret_request_params(:name)
          opts[:assembly_name] = assembly_name
        end

        if service_settings = ret_settings_objects(assembly_template)
          opts[:service_settings] = service_settings
        end

        if node_size = ret_request_params(:node_size)
          opts[:node_size] = node_size
        end

        if os_type = ret_request_params(:os_type)
          opts[:os_type] = os_type
        end

        new_assembly_obj = assembly_template.stage(target, opts)

        response = {
          new_service_instance: {
            name: new_assembly_obj.display_name_print_form,
            id: new_assembly_obj.id()
          },
          display_name: new_assembly_obj.display_name,
          id: new_assembly_obj.id
        }

        rest_ok_response(response)
      end

      def exec
        service    = service_object()
        params_hash = ret_params_hash(:commit_msg, :task_action, :task_params, :start_assembly, :skip_violations)
        rest_ok_response service.exec(params_hash)
      end


      def info
        service = service_object()
        rest_ok_response service.info
      end

      def nodes
        service = service_object()
        rest_ok_response service.info_about(:nodes)
      end

      def components
        service = service_object()

        opts = Opts.new(detail_level: nil)
        opts[:filter_proc] = Proc.new do |e|
          node = e[:node]
          (!node.is_a?(Node)) || !Node::TargetRef.is_target_ref?(node)
        end

        rest_ok_response service.info_about(:components, opts)
      end

      def tasks
        service = service_object()
        rest_ok_response service.info_about(:tasks)
      end

      def access_tokens
        service = service_object()
        rest_ok_response
      end

      def converge
        service = service_object()

        if running_task = most_recent_task_is_executing?(service)
          fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
        end

        unless task = Task.create_from_assembly_instance?(service, {})
          # TODO: double check this is right
          response =  {
            message: "There are no steps in the action to execute"
          }
          return rest_ok_response(response)
        end
        task.save!()

        workflow = Workflow.create(task)
        workflow.defer_execution()

        rest_ok_response task_id: task.id
      end

      def start
        service = service_object()

        # filters only stopped nodes for this assembly
        nodes, is_valid, error_msg = service.nodes_valid_for_stop_or_start(nil, :stopped)

        unless is_valid
          Log.info(error_msg)
          return rest_ok_response(errors: [error_msg])
        end

        opts = {}
        if (nodes.size == 1)
          opts.merge!(node: nodes.first)
        else
          opts.merge!(nodes: nodes)
        end

        task = Task.task_when_nodes_ready_from_assembly(service, :assembly, opts)
        task.save!()

        Node.start_instances(nodes)

        rest_ok_response task_id: task.id
      end

      def stop
        service = service_object()

        # cancel task if running on the assembly
        if running_task = most_recent_task_is_executing?(service)
          cancel_task(running_task.id)
        end

        nodes, is_valid, error_msg = service.nodes_valid_for_stop_or_start(nil, :running)

        unless is_valid
          Log.info(error_msg)
          return rest_ok_response(errors: [error_msg])
        end

        Node.stop_instances(nodes)

        rest_ok_response
      end

      def create_assembly
        service = service_object()
        assembly_template_name, service_module_name, module_namespace = get_template_and_service_names_params(service)

        if assembly_template_name.nil? || service_module_name.nil?
          fail ErrorUsage.new('SERVICE-NAME/ASSEMBLY-NAME cannot be determined and must be explicitly given')
        end

        project = get_default_project()
        opts = { mode: :create, local_clone_dir_exists: false }

        if namespace = ret_request_params(:namespace)
          opts.merge!(namespace: namespace)
        elsif ret_request_params(:use_module_namespace)
          opts.merge!(namespace: module_namespace)
        end

        if description = ret_request_params(:description)
          opts.merge!(description: description)
        end

        service_module = Assembly::Template.create_or_update_from_instance(project, service, service_module_name, assembly_template_name, opts)
        rest_ok_response service_module.ret_clone_update_info()
      end

      def delete_destroy
        service = service_object()

        Assembly::Instance.delete(service.id_handle(), destroy_nodes: true)

        rest_ok_response
      end

    end
  end
end
