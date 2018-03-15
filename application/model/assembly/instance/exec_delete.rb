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
module DTK; class  Assembly
  class Instance
    # delete functions dealing with tasks
    module ExecDeleteMixin
      def exec__delete_component(params, opts = {})
        task_action = params[:task_action]
        cmp_action  = nil
        delete_from_database = nil
        cmp_action = nil
        cmp_node   = nil
        
        task = Task.create_top_level(model_handle(:task), self, task_action: 'delete component')
        ret = {
          assembly_instance_id: id,
          assembly_instance_name: display_name_print_form
        }
        
        opts.merge!(skip_running_check: true)
        
        # check if action is called on component or on service instance action
        if task_action
          component_id, method_name = nil, nil
          
          if match = task_action.match(/^(.*)\.(\w*)$/)
            component_id, method_name = $1, $2
          else
            component_id = task_action
          end
          
          if component_id && component_id =~ /^[0-9]+$/
          if cmp_idh = params[:cmp_idh]
            p_component = cmp_idh.create_object.update_object!(:display_name)
            component_id = p_component[:display_name]
            cmp_node = p_component.get_node
          end
          end
          
          augmented_cmps = check_if_augmented_component(params, component_id, { include_assembly_cmps: true })
          
          # check if component and service level action with same name
          check_if_ambiguous(component_id) unless augmented_cmps.empty?
          
          if task_action.include?(ACTION_DELIMITER) || !augmented_cmps.empty?
            # return execute_cmp_action(params, component_id, method_name, augmented_cmps)
            task_params = nil
            component   = nil
            node        = nil
            
            task_params = params[:task_params]
            node        = (task_params['node'] || task_params['nodes']) if task_params
            
            message = "There are no components with identifier '#{component_id}'"
            message += " on node '#{node}'" if node
            fail ErrorUsage, "#{message}!" if augmented_cmps.empty?
            
            # if executing component action but node not sent, it means execute assembly component action
            unless node
              if cmp_node
                node = cmp_node[:display_name]
              else
                node = 'assembly_wide'
              end
            end
            
            opts.merge!(method_name: method_name) if method_name
            opts.merge!(task_params: task_params) if task_params
            
            if node
              # if node has format node:id it means use single node from node group
              if node_match = node.include?(':') && node.match(/([\w-]+)\:{1}(\d+)/)
                opts.merge!(node_group_member: node)
                node, node_id = $1, $2
              end
              
              # filter component that belongs to specified node
              component = augmented_cmps.find{|cmp| cmp[:node][:display_name].eql?(node)}
              fail ErrorUsage, "#{message}!" unless component
            end
            
            if cmp_node = component && component.get_node
              begin
                cmp_action = Task.create_for_ad_hoc_action(self, component, opts) if cmp_node.get_admin_op_status.eql?('running')
              rescue Task::Template::ParsingError => e
                raise e unless params[:noop_if_no_action]
              end
            end
          end
        end
        
        delete_from_database = Task.create_for_delete_from_database(self, component, node, opts)
        
        task.add_subtask(cmp_action) if cmp_action
        task.add_subtask(delete_from_database) if delete_from_database
        task = task.save_and_add_ids
        
        workflow = Workflow.create(task)
        workflow.defer_execution
        
        ret.merge!(task_id: task.id)
        ret
      end
      
      def exec__delete_node(node_idh, opts = {}) 
        assembly_instance = opts[:assembly_instance] || self
        task = opts[:top_task] || Task.create_top_level(model_handle(:task), assembly_instance, task_action: 'delete component')
        ret = {
          assembly_instance_id: assembly_instance.id,
          assembly_instance_name: assembly_instance.display_name_print_form
        }
        
        node = node_idh.create_object.update_object!(:display_name)
        opts.merge!(skip_running_check: true)
        if components = node.get_components
          cmp_opts = { method_name: 'delete', skip_running_check: true, delete_action: 'delete_component' }
          
          # order components by 'delete' action inside assembly workflow if exists
          ordered_components = order_components_by_workflow(components, Task.get_delete_workflow_order(assembly_instance))
          ordered_components.uniq.each do |component|
            next if component.get_field?(:component_type).eql?('ec2__node')
            cmp_action = nil
            cmp_top_task = Task.create_top_level(model_handle(:task), assembly_instance, task_action: "delete component '#{component.display_name_print_form}'")
            cmp_opts.merge!(delete_params: [component.id_handle, node.id])

            # fix to add :retry to the cmp_top_task
            task_template_content = get_task_template_content(model_handle(:task_template), component)
              task_template_content.each do |ttc|
                cmp = ttc[:components] || nil if ttc.is_a?(Hash)
                next if cmp.nil?
                cmp.first.gsub('::', '__').gsub(/\.[^\.]+$/, '') 
                component[:retry] = ttc[:retry] if cmp.include?(component[:display_name])
              end

            begin
              create_cmp_action = true
              if node_component = opts[:node_component]
                unless node_component.node.is_node_group?
                  create_cmp_action = node_component.node_is_running?
                end
              end

              cmp_action = Task.create_for_ad_hoc_action(assembly_instance, component, cmp_opts) if create_cmp_action    
            rescue Task::Template::ParsingError => e
              Log.info("Ignoring component 'delete' action does not exist.")
            end
            
            delete_cmp_from_database = Task.create_for_delete_from_database(assembly_instance, component, node, cmp_opts)
            cmp_top_task.add_subtask(cmp_action) if cmp_action
            cmp_top_task.add_subtask(delete_cmp_from_database) if delete_cmp_from_database
            task.add_subtask(cmp_top_task)
            
            # if cmp_action
              # cmp_top_task.add_subtask(cmp_action)
              # task.add_subtask(cmp_top_task)
            # end
          end
        end
        
        # command_and_control_action = Task.create_for_command_and_control_action(assembly_instance, 'destroy_node?', node_idh.get_id, node, opts)
        # delete_from_database = Task.create_for_delete_from_database(assembly_instance, nil, node, opts)
        
        # task.add_subtask(command_and_control_action) if command_and_control_action
        # task.add_subtask(delete_from_database) if delete_from_database
        return task if opts[:return_task]
        
        task = task.save_and_add_ids

        workflow = Workflow.create(task)
        workflow.defer_execution
        
        ret.merge!(task_id: task.id)
        ret
      end
      
      def exec__delete_node_group(node_idh, opts = {})
        task = Task.create_top_level(model_handle(:task), self, task_action: 'delete node group')
        ret = {
          assembly_instance_id: self.id,
          assembly_instance_name: self.display_name_print_form
        }
        opts.merge!(skip_running_check: true)
        
        node_group = node_idh.create_object
        group_members = node_group.get_node_group_members
        group_members.each do |node|
          group_member_task = exec__delete_node(node.id_handle, opts.merge(return_task: true))
          task.add_subtask(group_member_task) if group_member_task
        end
        delete_from_database = Task.create_for_delete_from_database(self, nil, node_group, opts.merge!(skip_running_check: true))
        task.add_subtask(delete_from_database) if delete_from_database
        task = task.save_and_add_ids
        
        workflow = Workflow.create(task)
        workflow.defer_execution
        
        ret.merge!(task_id: task.id)
        ret
      end
      # returns nil if there is no task to run
      def exec__delete(opts = {})
        task = Task.create_top_level(model_handle(:task), self, task_action: 'delete and destroy')
        ret = {
          assembly_instance_id: self.id,
          assembly_instance_name: self.display_name_print_form
        }
        opts.merge!(skip_running_check: true)
        
        staged_instances = get_staged_service_instances(self)
        service_instances = []
        staged_instances.each do |v|
          service_instances << v[:display_name]
        end
        
        if !opts[:recursive] && is_target_service_instance?
          fail ErrorUsage, "The context service cannot be deleted because there are service instances dependent on it (#{service_instances.join(', ')}). Please use flag '-r' to remove all." unless staged_instances.empty?
        end
        
        if opts[:recursive]
          fail ErrorUsage, "You can use recursive delete with target service instances only!" unless is_target_service_instance?
          delete_recursive(self, task, opts)
        end

        return nil unless self_subtask = delete_instance_task?(self, opts)

        if is_target_service_instance?
          task.add_subtask(self_subtask)
        else
          task = self_subtask
        end

        task = task.save_and_add_ids
        
        Workflow.create(task).defer_execution
        
        ret.merge(task_id: task.id)
      end

      private

      def delete_instance_task(assembly_instance, opts = {})
        delete_instance_task?(assembly_instance, opts) || fail(Error, "Unexpectd that delete_instance_task?(assembly_instance, opts) is nil")
      end

      def delete_instance_task?(assembly_instance, opts = {}) 
        task  = Task.create_top_level(model_handle(:task), assembly_instance, task_action: "delete and destroy '#{assembly_instance[:display_name]}'")
        has_steps = false
        nodes = assembly_instance.get_leaf_nodes(remove_assembly_wide_node: true)

        if assembly_wide_node = assembly_instance.has_assembly_wide_node?
          if components = assembly_wide_node.get_components
            cmp_opts = { method_name: 'delete', skip_running_check: true, delete_action: 'delete_component' }

            # order components by 'delete' action inside assembly workflow if exists
            ordered_components = order_components_by_workflow(components, Task.get_delete_workflow_order(assembly_instance))
            ordered_components.each do |component|
              cmp_top_task = Task.create_top_level(model_handle(:task), assembly_instance, task_action: "delete component '#{component.display_name_print_form}'")

              if component.is_node_component?
                node_component = NodeComponent.node_component(component)
                if node = node_component.node
                  node_top_task = exec__delete_node(node.id_handle, opts.merge(return_task: true, assembly_instance: assembly_instance, delete_action: 'delete_node', delete_params: [node.id_handle], top_task: task, node_component: node_component))
                end
              end

              cmp_action   = nil
              cmp_opts.merge!(delete_params: [component.id_handle, assembly_wide_node.id])

              # fix to add :retry to the cmp_top_task
              task_template_content = get_task_template_content(model_handle(:task_template), component)
                task_template_content.each do |ttc|
                  cmp = ttc[:components] || nil if ttc.is_a?(Hash)
                  next if cmp.nil?
                  cmp.first.gsub('::', '__').gsub(/\.[^\.]+$/, '') 
                  component[:retry] = ttc[:retry] if cmp.include?(component[:display_name])
                end

              begin                
                # no need to check if admin_op_status is 'running' with nodes as components so commented that out for now
                cmp_action = Task.create_for_ad_hoc_action(assembly_instance, component, cmp_opts)# if assembly_wide_node.get_admin_op_status.eql?('running')
              rescue Task::Template::ParsingError => e
                Log.info("Ignoring component 'delete' action does not exist.")
              end

              delete_cmp_from_database = Task.create_for_delete_from_database(assembly_instance, component, assembly_wide_node, cmp_opts)
              has_steps = true
              cmp_top_task.add_subtask(cmp_action) if cmp_action
              cmp_top_task.add_subtask(delete_cmp_from_database) if delete_cmp_from_database
              task.add_subtask(cmp_top_task)
            end
          end
        end

        unless has_steps
          if opts[:uninstall] # if called from uninstall and has no steps, do uninstall and return nil
            assembly_instance.uninstall(opts)
            return nil
          else
            fail ErrorUsage, "Service instance has no components to be deleted." 
          end
        end

        subtasks = task.subtasks
        subtasks.each_with_index do |sub, index|
          if sub.is_a?(Hash)
            if sub[:display_name].include?("ec2::node")
              ec2_node = sub              
              subtasks.delete_at(index)
              subtasks << ec2_node
            end
          end
        end

        unless opts[:donot_delete_assembly_from_database]
          delete_assembly_subtask = Task.create_for_delete_from_database(assembly_instance, nil, nil, opts.merge!(skip_running_check: true))
          task.add_subtask(delete_assembly_subtask)
        end

        task
      end
  
    end
  end
end; end
