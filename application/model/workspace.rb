module DTK
  class Workspace < Assembly::Instance
  # creates both a service, module branch, assembly instance and assembly templaet for the workspace
    def self.create?(target_idh,project_idh)
      Factory.create?(target_idh,project_idh)
    end

    def self.is_workspace?(obj)
      obj.kind_of?(self) or (AssemblyFields[:ref] == obj.get_field?(:ref))
    end

    def purge(opts={})
      opts.merge!(:do_not_raise => true)
      self.class.delete_contents([id_handle()],opts)
      delete_assembly_level_attributes()
      delete_tasks()
    end

    def set_target(target)
      current_target = get_target()
      if current_target.id ==  target.id
        raise ErrorUsage::Warning.new("Target is already set to #{target.get_field?(:display_name)}")
      end
      unless op_status_all_pending?()
        raise ErrorUsage.new("The command 'set-target' can only be invoked before the workspace has been converged (i.e., is in 'pending' state)")
      end
      update(:datacenter_datacenter_id => target.id)
    end

    def self.is_workspace_service_module?(service_module)
      service_module.get_field?(:display_name) == ServiceModuleFields[:display_name]
    end

   private
    def delete_tasks()
      clear_tasks(:include_executing_task => true)
    end

    def delete_assembly_level_attributes()
      assembly_attrs = get_assembly_level_attributes()
      return if assembly_attrs.empty?()
      Model.delete_instances(assembly_attrs.map{|r|r.id_handle()})
    end

    AssemblyFields = {
      :ref            => '__workspace',
      :component_type => 'workspace',
      :version        => 'master',
      :description => 'Private workspace'
    }
    ServiceModuleFields = {
      :display_name => '.workspace'
    }

    class Factory < self
      def self.create?(target_idh,project_idh)
        factory = new(target_idh,project_idh)
        workspace_template_idh = factory.create_assembly?(:template,:project_project_id => project_idh.get_id())
        instance_assigns = {
          :datacenter_datacenter_id => target_idh.get_id(),
          :ancestor_id => workspace_template_idh.get_id()
        }
        factory.create_assembly?(:instance,instance_assigns)
      end

      def create_assembly?(type,assigns)
        ref = AssemblyFields[:ref]
        match_assigns = {:ref => ref}.merge(assigns)
        other_assigns = {
          :display_name => AssemblyFields[:component_type],
          :component_type => AssemblyFields[:component_type],
          :version => AssemblyFields[:version],
          :description => AssemblyFields[:description],
          :module_branch_id => @module_branch_idh.get_id(),
          :type => (type == :template) ? 'template' : 'composite'
        }
        cmp_mh_with_parent = @component_mh.merge(:parent_model_name => (type == :template ? :project : :datacenter))
        Model.create_from_row?(cmp_mh_with_parent,ref,match_assigns,other_assigns)
      end
     private
      def initialize(target_idh,project_idh)
        @component_mh = target_idh.createMH(:component)
        module_and_branch_info = create_service_and_module_branch?(project_idh)
        @module_branch_idh = create_service_and_module_branch?(project_idh)
      end

      def create_service_and_module_branch?(project_idh)
        project = project_idh.create_object()
        service_module_name = ServiceModuleFields[:display_name]
        version = nil
        # TODO: Here namespace object is set to nil maybe this needs to be changed
        if service_module_branch = ServiceModule.get_workspace_module_branch(project,service_module_name,version,nil,:no_error_if_does_not_exist=>true)
          service_module_branch.id_handle()
        else
          opts_create = {:config_agent_type => ConfigAgentType}
          module_and_branch_info = ServiceModule.create_module(project,service_module_name,opts_create)
          service_module = module_and_branch_info[:module_idh].create_object()
          service_module.update(:dsl_parsed => true)
          module_and_branch_info[:module_branch_idh]
        end
      end
      ConfigAgentType = :puppet #TODO: stub
    end
  end
end
