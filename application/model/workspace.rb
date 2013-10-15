module DTK
  class Workspace < Assembly::Instance
  #creates both a service, module branch, assembly instance and assembly templaet for the workspace
    def self.create?(target_idh,project_idh)
      cmp_mh = target_idh.createMH(:component)
      module_branch_idh = create_service_and_module_branch?(project_idh)
      workspace_template_idh = create_assembly?(:template,cmp_mh,:module_branch_id => module_branch_idh.get_id(),:project_project_id => project_idh.get_id())
      instance_assigns = {
        :datacenter_datacenter_id => target_idh.get_id(),
        :ancestor_id => workspace_template_idh.get_id()
      }
      create_assembly?(:instance,cmp_mh,instance_assigns)
    end

    def self.is_workspace?(object)
      object.kind_of?(self) or (Ref == object.get_field?(:ref))
    end

    def purge(opts={})
      self.class.delete_contents([id_handle()],opts)
      delete_tasks()
    end

   private
    def self.create_service_and_module_branch?(project_idh)
      config_agent_type = :puupet #TODO: stub
      version = nil
      init_hash_response = ServiceModule.initialize_module(project_idh.create_object(),ServiceMoudleName,config_agent_type,version,:no_error_if_exists=>true)
      init_hash_response[:module_branch_idh]
    end
    ServiceMoudleName = '.workspace'

    def self.create_assembly?(type,cmp_mh,assigns)
      match_assigns = {:ref => Ref}.merge(assigns)
      other_assigns = {
        :display_name => 'workspace',
        :description => 'Private workspace',
        :type => (type == :template) ? 'template' : 'composite'
      }
      cmp_mh_with_parent = cmp_mh.merge(:parent_model_name => (type == :template ? :project : :datacenter))
      create_from_row?(cmp_mh_with_parent,Ref,match_assigns,other_assigns)
    end

    def delete_tasks()
      clear_tasks(:include_executing_task => true)
    end

    Ref = '__workspace'
  end
end
