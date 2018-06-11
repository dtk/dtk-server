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
        Log.info("Starting converge on service: #{assembly_instance.display_name_print_form}")
        if running_task = most_recent_task_is_executing?(assembly_instance)
          fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
        end

        violations = assembly_instance.find_violations
        unless violations.empty?
          Log.debug("Found violations: #{violations}")
          return rest_ok_response({ violations: violations.table_form }, datatype: :violation)
        end

        opts = {
          start_nodes: true,
          ret_nodes_to_start: []
        }
        unless task = Task.create_from_assembly_instance?(assembly_instance, opts)
          fail ErrorUsage, "There are no steps in the action to execute"
        end
        task.save!

        # TODO: DTK-2915; not sure if we need any more; test this when converge from stopped state
        # still have to use start_instances until we implement this to start from workflow task
        unless (opts[:ret_nodes_to_start]||[]).empty?
          Node.start_instances(opts[:ret_nodes_to_start])
        end

        if assembly_wide_node = assembly_instance.has_assembly_wide_node?
          assembly_wide_node.update_admin_op_status!(:running)
        end

        task_name_list = task[:subtasks].map {|x| x[:display_name]}
        Log.info("Executing tasks: #{task_name_list}")
        execute_task(task)

        rest_ok_response task_id: task.id
      end

      def delete
        recursive = boolean_request_params(:recursive)

        opts_hash = {
          delete_action: 'delete',
          delete_params: [assembly_instance.id_handle],
          recursive: recursive,
          donot_delete_assembly_from_database: true,
          delete_only: true
        }        

        nodes = assembly_instance.info_about(:nodes, datatype: :node)
        exec__delete_info = assembly_instance.exec__delete(Opts.new(opts_hash))

        if exec__delete_info[:has_ec2]
          rest_ok_response nodes
        else
          rest_ok_response
        end
      end

      def uninstall
        recursive = boolean_request_params(:recursive)
        delete    = boolean_request_params(:delete)
        force     = boolean_request_params(:force)

        if force || !delete
          assembly_instance.uninstall(recursive: recursive, delete: delete, force: force)
        else
          opts_hash = {
            delete_action: 'delete',
            delete_params: [assembly_instance.id_handle],
            recursive: recursive,
            uninstall: true,
            delete: delete,
            force: force
          }

          exec__delete_info = assembly_instance.exec__delete(Opts.new(opts_hash))
        end

        response = 
          if !exec__delete_info.nil? && (exec__delete_info[:has_ec2] || opts_hash[:uninstall])
            { message: "Uninstall started. For more information use 'dtk task-status'."}
          elsif force
            { message: "The service instance is uninstalled with '--force' flag. If you want to delete nodes, you will need to do it manually"}
          else
            { message: "Delete procedure started. For more information use 'dtk task-status'."}
          end
        
        rest_ok_response response
      end

      def exec
        params_hash = params_hash(:commit_msg, :task_action, :task_params, :start_assembly, :skip_violations)
        # Need to get breakpoint as boolean since by default in params_hash method it returns as string
        breakpoint = boolean_request_params(:breakpoint)
        sleep      = request_params(:sleep)
        attempts    = request_params(:attempts)

        params_hash.merge!(:sleep => sleep.to_i) if sleep.to_i > 0
        params_hash.merge!(:attempts => attempts.to_i) if attempts.to_i >0
        params_hash.merge!(:breakpoint => breakpoint)
        response = assembly_instance.exec(params_hash)
        if response[:violations]
          rest_ok_response response, datatype: :violation
        else
          rest_ok_response response
        end
      end

      def set_attributes
        rest_ok_response assembly_instance.set_attributes(ret_params_av_pairs, update_meta: true, update_dsl: true)
      end
      
      def set_attribute
       assembly       = assembly_instance()
       opts           = ret_params_hash(:service_instance, :pattern, :value)
       av_pairs       = ret_params_av_pairs()
       
       if semantic_data_type = ret_request_params(:datatype)
         unless Attribute::SemanticDatatype.isa?(semantic_data_type)
           fail ErrorUsage.new("The term (#{semantic_data_type}) is not a valid data type")
         end
         create_options.merge!(semantic_data_type: semantic_data_type)
       end

       # update_meta == true is the default
       update_meta = ret_request_params(:update_meta)
       opts.merge!(update_meta: true) unless !update_meta.nil? && !update_meta
       opts.merge!(update_dsl: true)
       
       response = assembly.set_attributes(av_pairs, opts)
       response.merge!(repo_updated: true)

       rest_ok_response response    
      end

      def update_from_repo
        commit_sha = required_request_params(:commit_sha)
        updated_nested_modules = ret_request_params(:updated_nested_modules)
        diff_result = CommonModule::Update::ServiceInstance.update_from_repo(get_default_project, commit_sha, service_instance, { :updated_nested_modules => updated_nested_modules})
        rest_ok_response diff_result.hash_for_response
      end

      # params passed to link are
       #  required
       #    :base_component - string in form that appears in 'dtk components'
       #    :dep_component - string in form that appears in 'dtk components'
       #  optional
       #    :service - string that is external service associated with dep_component
       #    :unlink  - boolean meaning to unlink, rather than link (default is false)
       #    :link_name - string optionally given
       def link
         # TODO: DTK-3009; stub for Almin
         assembly = dep_assembly = assembly_instance()

         unless request_params(:service).empty? 
           dep_assembly = external_assembly_instance(:service)
         end
         unlink = boolean_request_params(:unlink)
         link_name = request_params(:link_name) 
         link_name = nil if link_name.empty?

         base_component = ret_component_id_handle(:base_component, assembly).create_object()
         dep_component  = ret_component_id_handle(:dep_component, dep_assembly).create_object()

         service_link_idh = 
          if unlink 
             opts =  (link_name ? { link_name: link_name } : {})
             assembly.remove_component_link(base_component, dep_component, opts)
           else
             opts =  (link_name ? { link_name: link_name } : {})
             assembly.add_component_link(base_component, dep_component, opts)
           end
        rest_ok_response service_link_idh
       end

      def set_default_target
        rest_ok_response assembly_instance.set_as_default_target
      end

      # TODO: move most of this logic from controller to model
      def eject
        assembly_instance = assembly_instance()
        component_ref     = required_request_params(:component_ref)

        components = assembly_instance.info_about(:components)
        components.reject! { |comp| !component_ref.eql?(comp[:display_name]) }

        fail ErrorUsage.new("Component '#{component_ref}' does not match any components") if components.empty?
        fail ErrorUsage.new("Unexpected that component name '#{component_ref}' match multiple components") if components.size > 1

        component      = components.first
        aug_components = assembly_instance.get_augmented_components
        matching_components = aug_components.select { |comp| component[:id] == comp[:id] }

        fail ErrorUsage.new("Component '#{component_ref}' does not match any components") if matching_components.empty?
        fail ErrorUsage.new("Unexpected that component name '#{component_ref}' match multiple components") if matching_components.size > 1

        component = ::DTK::Component::Instance.create_from_component(matching_components.first)
        node      = component.get_node
        assembly_instance.delete_component(component.id_handle, node.id, { delete_node_as_component_node: true})

        service_instance_branch = assembly_instance.get_service_instance_branch
        DTK::CommonDSL::Generate::ServiceInstance.generate_dsl_and_push!(assembly_instance, service_instance_branch)

        response = CommonModule::ModuleRepoInfo.new(service_instance_branch)
        response.merge!(repo_updated: true)

        rest_ok_response response
      end

      def delete_by_path
        rest_ok_response assembly_instance.delete_by_path(required_request_params(:path))
      end

      def add_by_path
        rest_ok_response assembly_instance.add_by_path(required_request_params(:path), required_request_params(:content))
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
