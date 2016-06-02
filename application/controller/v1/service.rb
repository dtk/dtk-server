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
      helper_v1 :module_ref_helper
      helper :assembly_helper
      helper :task_helper

      ### For creating a service instance from an assembly
      ## Params are
      ##   :assembly_name
      ##   :module_id, :module_name, :namespace - Either 'module_id' or 'module_name and namespace' must be given
      ##   :target_id - parent target id (optional)
      ##   :name (optional) - name for new instance
    def create
      assembly_name  = required_request_params(:assembly_name)
      service_module = ret_service_module
      version        = request_params(:version) || compute_latest_version(service_module)

#      unless assembly_template = service_module.assembly_template(assembly_name, version)
       fail ErrorUsage, "The assembly '#{assembly_name}' does not exist in module '#{service_module.name_with_namespace}'"
#      end
pp assembly_template
      return rest_ok_response

      if no_auto_complete = ret_request_params(:no_auto_complete)
        opts[:no_auto_complete] = no_auto_complete
      end

      project = get_default_project()
      opts.merge!(project: project)

      if assembly_name = ret_request_params(:name)
        opts[:assembly_name] = assembly_name
      end

      target = nil
      target_assembly_instance =  nil
      if is_target_service = ret_request_params(:is_target)
        opts[:is_target_service] = true
        target_name = assembly_name || "#{service_module[:display_name]}-#{assembly_template[:display_name]}"
        target = Service::Target.create_target_mock(target_name, project)
        target_assembly_instance = ret_assembly_instance_object?(:parent_service)
      else
        # this case is for service instance which are staged against a target service instance
        # which is giving  parameter 'parent-service' or getting default target
        target_service = ret_target_service_with_default(:parent_service)
        raise_error_if_target_not_convereged(target_service)
        target = target_service.target
        target_assembly_instance = target_service.assembly_instance
      end

      opts.merge!(parent_service_instance: target_assembly_instance) if target_assembly_instance

      begin
        new_assembly_obj = assembly_template.stage(target, opts)
      rescue DTK::ErrorUsage => e
        # delete mocked target service instance created above
        Target::Instance.delete_and_destroy(target) if is_target_service
        raise e unless is_silent_fail
        # in case we are using silent fail we wont response evne if there was an error
        new_assembly_obj = Assembly::Instance.find_by_name?(target, opts[:assembly_name])
        is_created = false
        # in case there is still no assembly raise error
        raise e unless new_assembly_obj
      end

      if is_target_service
        display_name = new_assembly_obj.get_field?(:display_name)
        ref          = display_name.downcase.gsub(/ /, '-')
        target.update(display_name: display_name, ref: ref)
      end

      response = {
        new_service_instance: {
          name: new_assembly_obj.display_name_print_form,
          id: new_assembly_obj.id(),
          is_created: is_created
        }
      }

      if ret_request_params(:do_not_encode)
        rest_ok_response(response)
      else
        rest_ok_response(response, encode_into: :yaml)
      end
    end

      def exec
        service     = service_object()
        params_hash = params_hash(:commit_msg, :task_action, :task_params, :start_assembly, :skip_violations)
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

        if namespace = request_params(:namespace)
          opts.merge!(namespace: namespace)
        elsif request_params(:use_module_namespace)
          opts.merge!(namespace: module_namespace)
        end

        if description = request_params(:description)
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
