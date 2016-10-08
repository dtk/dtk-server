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
        service_module    = ret_service_module
        is_target_service = boolean_request_params(:is_target)
        assembly_name     = request_params(:assembly_name) # could be empty means look for unique assembly in service module

        if version = request_params(:version)
          version = nil if BASE_VERSION_STRING.include?(version)
        else
           version = compute_latest_version(service_module)
        end
        assembly_template = service_module.assembly_template(assembly_name: assembly_name, version: version)
        service_name = request_params(:service_name) || generate_new_service_name(assembly_template, service_module)

        opts = {
          project: get_default_project,
          service_module: service_module,
          service_name: service_name,
          no_auto_complete: boolean_request_params(:no_auto_complete),
          version: version,
          add_nested_modules: true 
        }
        opts = Opts.new(opts)

        response =
          if is_target_service
            target_name = service_name || "#{service_module[:display_name]}-#{assembly_template[:display_name]}"
            Service::Target.stage_target_service(assembly_template, CommonModule::ServiceInstance, opts.merge(target_name: target_name))
          else
            target_service = ret_target_service_with_default(:target_service, new_client: true)
            # TODO: for testing
            #opts = opts.merge!(allow_existing_service: true)
            target_service.stage_service(assembly_template, CommonModule::ServiceInstance, opts)
          end
        rest_ok_response response
      end
      BASE_VERSION_STRING = ['base', 'master'] #TODO: settle on one

      ### Service instance specific
      def cancel_last_task
        if running_task = most_recent_task_is_executing?(assembly_instance)
          top_task_id = running_task.id()
        else
          fail ErrorUsage.new('No running tasks found')
        end

        cancel_task(top_task_id)
        rest_ok_response task_id: top_task_id
      end

      def generate_service_name
        service_module    = ret_service_module
        assembly_name     = request_params(:assembly_name)

        if version = request_params(:version)
          version = nil if BASE_VERSION_STRING.include?(version)
        else
           version = compute_latest_version(service_module)
        end

        assembly_template = service_module.assembly_template(assembly_name: assembly_name, version: version)
        rest_ok_response generate_new_service_name(assembly_template, service_module)
      end

      def converge
        assembly_instance = assembly_instance()
        if running_task = most_recent_task_is_executing?(assembly_instance)
          fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
        end

        opts = {
          start_nodes: true,
          ret_nodes_to_start: []
        }

        unless task = Task.create_from_assembly_instance?(assembly_instance, opts)
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
        Assembly::Instance.delete(assembly_instance.id_handle, destroy_nodes: true)
        rest_ok_response
      end

      def exec
        params_hash = params_hash(:commit_msg, :task_action, :task_params, :start_assembly, :skip_violations)
        rest_ok_response assembly_instance.exec(params_hash)
      end

      def set_attributes
        rest_ok_response assembly_instance.set_attributes(ret_params_av_pairs, update_meta: true, update_dsl: true)
      end

      def start
        assembly_instance = assembly_instance()

        # filters only stopped nodes for this assembly
        nodes, is_valid, error_msg = assembly_instance.nodes_valid_for_stop_or_start(nil, :stopped)

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

        task = Task.task_when_nodes_ready_from_assembly(assembly_instance, :assembly, opts)
        task.save!

        Node.start_instances(nodes)

        execute_task(task)

        rest_ok_response task_id: task.id
      end

      def stop
        assembly_instance = assembly_instance()

        # cancel task if running on the assembly
        if running_task = most_recent_task_is_executing?(assembly_instance)
          cancel_task(running_task.id)
        end

        nodes, is_valid, error_msg = assembly_instance.nodes_valid_for_stop_or_start(nil, :running)

        unless is_valid
          Log.info(error_msg)
          return rest_ok_response(errors: [error_msg])
        end

        Node.stop_instances(nodes)

        rest_ok_response
      end

      def update_from_repo
        commit_sha = required_request_params(:commit_sha)
        diff_result = CommonModule.update_from_repo(:service_instance, get_default_project, commit_sha, service_instance: service_instance)
        rest_ok_response diff_result.hash_for_response
      end

      def set_default_target
        rest_ok_response assembly_instance.set_as_default_target
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
