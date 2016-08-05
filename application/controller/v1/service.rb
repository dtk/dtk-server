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
      helper_v1 :service_helper
      helper :assembly_helper
      helper :task_helper

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
        service_name      = request_params(:service_name)
        is_target_service = boolean_request_params(:is_target)

        unless assembly_template = service_module.assembly_template?(assembly_name, version)
          fail ErrorUsage, "The assembly '#{assembly_name}' does not exist in module '#{service_module.name_with_namespace}'"
        end
        
        opts = {
          project: get_default_project,
          service_module: service_module,
          service_name: request_params(:service_name) || generate_new_service_name(assembly_name, service_module),
          no_auto_complete: boolean_request_params(:no_auto_complete),
        }
        opts = Opts.new(opts)

        response = 
          if is_target_service
            target_name = assembly_name || "#{service_module[:display_name]}-#{assembly_template[:display_name]}"
            Service::Target.stage_target_service(assembly_template, CommonModule::ServiceInstance, opts.merge(target_name: target_name))
          else
            target_service = ret_target_service_with_default(:target_service)
            # TODO: for testing; might remove
            opts = opts.merge!(allow_existing_service: true) # TODO: for testing; might remove
            target_service.stage_service(assembly_template, CommonModule::ServiceInstance, opts)
          end
        rest_ok_response response
      end

      def update_from_repo
        namespace, module_name, repo_name, commit_sha = required_request_params(:namespace, :module_name, :repo_name, :commit_sha)
        version = request_params(:version)
        local_params = local_params(:common_module, module_name, namespace: namespace, version: version)
        rest_ok_response CommonModule.update_from_repo(:service_instance, get_default_project, local_params, repo_name, commit_sha, { force_pull: true })
      end

      def delete
        service = service_object
        Assembly::Instance.delete(service.id_handle, destroy_nodes: true)
        rest_ok_response
      end

      def repo_info
        service = service_object
        rest_ok_response CommonModule::ServiceInstance.get_repo_info(service)
      end

      def exec
        service     = service_object
        params_hash = params_hash(:commit_msg, :task_action, :task_params, :start_assembly, :skip_violations)
        rest_ok_response service.exec(params_hash)
      end

      def info
        service = service_object
        rest_ok_response service.info
      end

      def nodes
        service = service_object
        rest_ok_response service.info_about(:nodes), datatype: :node
      end

      def components
        service  = service_object
        datatype = :component

        opts = Opts.new(detail_level: nil)
        opts[:filter_proc] = Proc.new do |e|
          node = e[:node]
          (!node.is_a?(Node)) || !Node::TargetRef.is_target_ref?(node)
        end

        if request_params(:dependencies)
          opts.merge!(detail_to_include: [:component_dependencies])
          datatype = :component_with_dependencies
        end

        rest_ok_response service.info_about(:components, opts), datatype: datatype
      end

      def tasks
        service = service_object
        rest_ok_response service.info_about(:tasks)
      end

      def access_tokens
        service = service_object
        rest_ok_response
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

      def create_assembly
        service = service_object
        assembly_template_name, service_module_name, module_namespace = get_template_and_service_names_params(service)

        if assembly_template_name.nil? || service_module_name.nil?
          fail ErrorUsage.new('SERVICE-NAME/ASSEMBLY-NAME cannot be determined and must be explicitly given')
        end

        project = get_default_project
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
        rest_ok_response service_module.ret_clone_update_info
      end

      def task_status
        rest_ok_response Task::Status::Assembly.get_status(service_object.id_handle, format: :table), datatype: :task_status
      end

      def list_violations
        violations = service_object.find_violations
        rest_ok_response violations.table_form, datatype: :violation
      end

      def list
        params_hash = params_hash(:filter, :detail_level, :include_namespaces).merge(remove_assembly_wide_node: true)
        rest_ok_response Assembly::Instance.list(model_handle(), params_hash), datatype: :assembly
      end

      def actions
        type = request_params(:type)
        rest_ok_response service_object.list_actions(type), datatype: :service_actions
      end

      def attributes
        service           = service_object
        detail_to_include = []
        datatype          = :workspace_attribute
        opts              = Opts.new(detail_level: nil)

        if request_params(:links)
          detail_to_include << :attribute_links
          datatype = :workspace_attribute_w_link
        end

        if node_id = request_params(:node_id)
          node_id = "#{ret_node_id(:node_id, service)}" unless (node_id =~ /^[0-9]+$/)
          opts.merge!(node_cmp_name: true)
        end

        if component_id = request_params(:component_id)
          component_id = "#{ret_component_id(:component_id, service, filter_by_node: true)}" unless (component_id =~ /^[0-9]+$/)
        end

        additional_filter_proc = Proc.new do |e|
          attr = e[:attribute]
          (!attr.is_a?(Attribute)) || !attr.filter_when_listing?({})
        end

        opts[:filter_proc] = Proc.new do |element|
          if element_matches?(element, [:node, :id], node_id) && element_matches?(element, [:attribute, :component_component_id], component_id)
            element if additional_filter_proc.nil? || additional_filter_proc.call(element)
          end
        end

        opts.merge!(detail_to_include: detail_to_include.map(&:to_sym)) unless detail_to_include.empty?
        rest_ok_response service.info_about(:attributes, opts), datatype: datatype
      end

      def list_component_links
        rest_ok_response service_object.list_service_links(hide_assembly_wide_node: true), datatype: :service_link
      end

      def list_dependent_modules
        rest_ok_response service_object.info_about(:modules, Opts.new(detail_to_include: [:version_info])), datatype: :assembly_component_module
      end

      def cancel_last_task
        if running_task = most_recent_task_is_executing?(service_object)
          top_task_id = running_task.id()
        else
          fail ErrorUsage.new('No running tasks found')
        end

        cancel_task(top_task_id)
        rest_ok_response task_id: top_task_id
      end

      def required_attributes
        rest_ok_response service_object.get_attributes_print_form(Opts.new(filter: :required_unset_attributes))
      end

      def set_attributes
        service_object.set_attributes(ret_params_av_pairs, update_meta: true)
        rest_ok_response
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
