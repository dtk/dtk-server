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
  class V1::ServiceController
    module PostMixin
      ### For all services

      ### For creating a service instance from an assembly
      ## Params are
      ##   :assembly_name
      ##   :module_id, :module_name, :namespace - Either 'module_id' or 'module_name and namespace' must be given
      ##   :target_service (optional) - id or name of target (parent) service; if omitted default is used
      ##   :service_name (optional) - name for new service instance
      ##   :is_target (optional) - Boolean
      ##   :no_auto_complete(optional) - Boolean
      def create
        assembly_name     = required_request_params(:assembly_name)
        service_module    = ret_service_module
        version           = request_params(:version) || compute_latest_version(service_module)
        service_name      = request_params(:service_name) || generate_new_service_name(assembly_name, service_module)
        is_target_service = boolean_request_params(:is_target)

        unless assembly_template = service_module.assembly_template?(assembly_name, version)
          fail ErrorUsage, "The assembly '#{assembly_name}' does not exist in module '#{service_module.name_with_namespace}'"
        end

        opts = {
          project: get_default_project,
          service_module: service_module,
          service_name: service_name,
          no_auto_complete: boolean_request_params(:no_auto_complete),
        }
        opts = Opts.new(opts)

        response =
          if is_target_service
            target_name = service_name || "#{service_module[:display_name]}-#{assembly_template[:display_name]}"
            Service::Target.stage_target_service(assembly_template, CommonModule::ServiceInstance, opts.merge(target_name: target_name))
          else
            target_service = ret_target_service_with_default(:target_service, new_client: true)
            # TODO: for testing; might remove
            opts = opts.merge!(allow_existing_service: true) # TODO: for testing; might remove
            target_service.stage_service(assembly_template, CommonModule::ServiceInstance, opts)
          end
        rest_ok_response response
      end

      ### Service instance specific
      def cancel_last_task
        if running_task = most_recent_task_is_executing?(service_object)
          top_task_id = running_task.id()
        else
          fail ErrorUsage.new('No running tasks found')
        end

        cancel_task(top_task_id)
        rest_ok_response task_id: top_task_id
      end

      def converge
        service = service_object

        if running_task = most_recent_task_is_executing?(service)
          fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
        end

        opts = {
          start_nodes: true,
          ret_nodes_to_start: []
        }

        unless task = Task.create_from_assembly_instance?(service, opts)
          return rest_ok_response({ message: "There are no steps in the action to execute" })
        end

        task.save!

        # still have to use start_instances until we implement this to start from workflow task
        unless (opts[:ret_nodes_to_start]||[]).empty?
          Node.start_instances(opts[:ret_nodes_to_start])
        end

        execute_task(task)

        rest_ok_response task_id: task.id
      end

      def delete
        service = service_object
        Assembly::Instance.delete(service.id_handle, destroy_nodes: true)
        rest_ok_response
      end

      def exec
        service     = service_object
        params_hash = params_hash(:commit_msg, :task_action, :task_params, :start_assembly, :skip_violations)
        rest_ok_response service.exec(params_hash)
      end

      def set_attributes
        service_object.set_attributes(ret_params_av_pairs, update_meta: true)
        rest_ok_response
      end

      def start
        service = service_object

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
        task.save!

        Node.start_instances(nodes)

        execute_task(task)

        rest_ok_response task_id: task.id
      end

      def stop
        service = service_object

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

      def update_from_repo
        service = service_object
        commit_sha = required_request_params(:commit_sha)
        rest_ok_response CommonModule::ServiceInstance.update_from_repo(get_default_project, service, commit_sha)
      end

      def set_default_target
        rest_ok_response service_object.set_as_default_target
      end

      def create_workspace
        workspace_name  = ret_request_params(:workspace_name)
        default_project = get_default_project

        unless workspace_name
          instance_list  = Assembly::Instance.list_with_workspace(model_handle)
          workspace_name = Workspace.calculate_workspace_name(instance_list)
        end

        target_service = ret_target_service_with_default(:target_service, new_client: true)
        raise_error_if_target_not_convereged(target_service, is_workspace: true)
        target = target_service.target
        target_service_instance = target_service.assembly_instance

        opts = Opts.new(project: default_project)
        opts.merge!(parent_service_instance: target_service_instance) if target_service_instance

        workspace = Workspace.create?(target.id_handle, default_project.id_handle, workspace_name, opts)

        response = {
          workspace: {
            name: workspace[:display_name],
            id: workspace[:guid]
          }
        }

        rest_ok_response response
      end

      private

      def execute_task(task)
        reified_task = Task::Hierarchical.get_and_reify(task.id_handle)
        workflow = Workflow.create(reified_task)
        workflow.defer_execution
      end
    end
  end
end
