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
  class Workspace < Assembly::Instance
    r8_require('service_associations')

    def self.create_from_id_handle(idh)
      idh.create_object(model_name: :assembly_workspace)
    end

    # creates both a service, module branch, assembly instance and assembly template for the workspace
    def self.create?(target_idh, project_idh, workspace_name = nil, opts = {})
      Factory.create?(target_idh, project_idh, workspace_name, opts)
    end

    def self.is_workspace?(obj)
      # obj.is_a?(self) || (AssemblyFields[:ref] == obj.get_field?(:ref))
      obj.is_a?(self) || (obj.get_field?(:ref).start_with?(AssemblyFields[:ref]))
    end
    # if is workspace it convents to workspace object
    def self.workspace?(obj)
      if is_workspace?(obj)
        create_from_id_handle(obj.id_handle).merge(obj)
      end
    end

    def self.get_workspace(workspace_mh, opts = {})
      opts_get = Aux.hash_subset(opts, :cols).merge(filter: [:eq, :ref, AssemblyFields[:ref]])
      rows = Workspace.get(workspace_mh, opts_get)
      unless rows.size == 1
        # Log.error_pp(['Unexpected that get_workspace does not return 1 row', rows])
        return nil
      end
      rows.first
    end

    def self.get_workspaces(workspace_mh, opts = {})
      opts_get = Aux.hash_subset(opts, :cols).merge(filter: [:eq, :component_type, AssemblyFields[:component_type]])
      Workspace.get(workspace_mh, opts_get)
    end

    def purge(opts = {})
      opts.merge!(do_not_raise: true)
      self.class.delete_contents([id_handle()], opts)
      delete_assembly_level_attributes()
      delete_tasks()
      delete_module_ref_locks()
    end

    # opts has :mode
    # three modes
    #   :direct - direct command called (default)
    #   :from_set_default_target
    #   :from_delete_target
    def self.set_target(target, opts = {})
      if workspace = get_workspace(target.model_handle(:assembly_workspace))
         workspace.set_target(target, opts)
      end
    end
    def set_target(target, opts = {})
      return unless target
      mode = opts[:mode] || :direct
      current_target = get_target()
      if current_target && current_target.id == target.id
        if mode == :direct
          fail ErrorUsage::Warning.new("Target is already set to #{target.get_field?(:display_name)}")
        end
        return
      end

      update = true
      unless node_admin_status_all_pending?()
        case mode
         when :direct
          fail ErrorUsage.new("The command 'set-target' can only be invoked before the workspace has been converged (i.e., is in 'pending' state)")
         when :from_set_default_target
          # treated as no op (keep workspace as is)
          update = false
         when :from_delete_target
          # want to update so deleting target does not have foreign key that causes the workspace object to be deleted
          update = true
         else
          fail Error.new("Unexpected mode '#{mode}'")
        end
      end
      if update
        update(datacenter_datacenter_id: target.id)
      end
    end

    def self.is_workspace_service_module?(service_module)
      service_module.get_field?(:display_name) == ServiceModuleFields[:display_name]
    end

    def self.is_workspace_service_module?(service_module)
      service_module.get_field?(:display_name) == ServiceModuleFields[:display_name]
    end

    def self.calculate_workspace_name(assembly_list)
      name = AssemblyFields[:component_type]
      workspace_list = assembly_list.select{ |assembly| (assembly[:ref]||"").start_with?(AssemblyFields[:ref]) }

      unless workspace_list.empty?
        numbers = []
        base_name = nil

        workspace_list.each do |workspace|
          match = workspace[:display_name].match(/#{name}(-)(\d*)/)
          base_name = name if name.include?(workspace[:display_name])
          numbers << match[2].to_i if match
        end

        if base_name
          highest = numbers.max||1
          new_highest = highest + 1

          all = (2..new_highest).to_a
          nums = all - numbers
          name = "#{name}-#{nums.first}"
        end
      end

      name
    end

    private

    def delete_tasks
      clear_tasks(include_executing_task: true)
    end

    def delete_assembly_level_attributes
      assembly_attrs = get_assembly_level_attributes()
      return if assembly_attrs.empty?()
      Model.delete_instances(assembly_attrs.map(&:id_handle))
    end

    def delete_module_ref_locks()
      ModuleRefs::Lock.create_or_update(self)
    end

    AssemblyFields = {
      ref: '__workspace',
      component_type: 'workspace',
      version: 'master',
      description: 'Private workspace'
    }
    ServiceModuleFields = {
      display_name: '.workspace'
    }

    class Factory < self
      def self.create?(target_idh, project_idh, workspace_name = nil, opts = {})
        factory = new(target_idh, project_idh)
        workspace_template_idh = factory.create_assembly?(:template, project_project_id: project_idh.get_id())
        instance_assigns = {
          datacenter_datacenter_id: target_idh.get_id(),
          ancestor_id: workspace_template_idh.get_id()
        }
        factory.create_assembly?(:instance, instance_assigns, workspace_name, opts)
      end

      def create_assembly?(type, assigns, workspace_name = nil, opts = {})
        ref = workspace_name ? "#{AssemblyFields[:ref]}_#{workspace_name}" : AssemblyFields[:ref]
        display_name = workspace_name ? workspace_name : AssemblyFields[:component_type]
        match_assigns = { ref: ref }.merge(assigns)

        other_assigns = {
          display_name: display_name,
          component_type: AssemblyFields[:component_type],
          version: AssemblyFields[:version],
          description: AssemblyFields[:description],
          module_branch_id: @module_branch_idh.get_id(),
          type: (type == :template) ? 'template' : 'composite'
        }
        cmp_mh_with_parent = @component_mh.merge(parent_model_name: (type == :template ? :project : :datacenter))
        assembly_idh = Model.create_from_row?(cmp_mh_with_parent, ref, match_assigns, other_assigns)
        assembly_instance = Assembly::Instance.create_subclass_object(assembly_idh.create_object())

        if parent_service_instance = opts[:parent_service_instance]
          ServiceAssociations.create_associations(opts[:project], assembly_instance, parent_service_instance) if assembly_instance
        end

        unless opts[:no_auto_complete]
          aug_cmps = assembly_instance.get_augmented_components(opts)
          LinkDef::AutoComplete.autocomplete_component_links(assembly_instance, aug_cmps, opts)
        end

        assembly_idh
      end

      private

      def initialize(target_idh, project_idh)
        @component_mh = target_idh.createMH(:component)
        module_and_branch_info = create_service_and_module_branch?(project_idh)
        @module_branch_idh = create_service_and_module_branch?(project_idh)
      end

      def create_service_and_module_branch?(project_idh)
        project = project_idh.create_object()
        service_module_name = ServiceModuleFields[:display_name]
        version = nil
        # TODO: Here namespace object is set to nil maybe this needs to be changed
        if service_module_branch = ServiceModule.get_workspace_module_branch(project, service_module_name, version, nil, no_error_if_does_not_exist: true)
          service_module_branch.id_handle()
        else
          local_params = ModuleBranch::Location::LocalParams::Server.new(
            module_type: :service_module,
            module_name: service_module_name,
            namespace: Namespace.default_namespace(project.model_handle(:namespace)),
            version: version
          )

          # TODO: look to remove :config_agent_type
          module_and_branch_info = ServiceModule.create_module(project, local_params, config_agent_type: ConfigAgent::Type.default_symbol)
          service_module = module_and_branch_info[:module_idh].create_object()
          service_module.update(dsl_parsed: true)

          branch_idh = module_and_branch_info[:module_branch_idh]
          branch = branch_idh.create_object()
          branch.set_dsl_parsed!(true)

          branch_idh
        end
      end
    end
  end
end