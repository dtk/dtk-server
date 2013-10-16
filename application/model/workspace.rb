module DTK
  class Workspace < Assembly::Instance
  #creates both a service, module branch, assembly instance and assembly templaet for the workspace
    def self.create?(target_idh,project_idh)
      Factory.create?(target_idh,project_idh)
    end

    def self.is_workspace?(object)
      object.kind_of?(self) or (workspace_ref() == object.get_field?(:ref))
    end

    def purge(opts={})
      self.class.delete_contents([id_handle()],opts)
      delete_tasks()
    end

    def self.workspace_ref()
      Ref
    end
    Ref = '__workspace'

   private
    def delete_tasks()
      clear_tasks(:include_executing_task => true)
    end
    
    class Factory
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
        match_assigns = {:ref => Workspace.workspace_ref()}.merge(assigns)
        other_assigns = {
          :display_name => ComponentType,
          :component_type => ComponentType,
          :version => ComponentVersion,
          :description => 'Private workspace',
          :module_branch_id => @module_branch_idh.get_id(),
          :type => (type == :template) ? 'template' : 'composite'
        }
        cmp_mh_with_parent = @component_mh.merge(:parent_model_name => (type == :template ? :project : :datacenter))
        Model.create_from_row?(cmp_mh_with_parent,Ref,match_assigns,other_assigns)
      end
      ComponentType = 'workspace'
      ComponentVersion = 'master'
     private
      def initialize(target_idh,project_idh)
        @component_mh = target_idh.createMH(:component)
        module_and_branch_info = create_service_and_module_branch?(project_idh)
        @module_branch_idh = module_and_branch_info[:module_branch_idh]
      end
      
      def create_service_and_module_branch?(project_idh)
        config_agent_type = :puppet #TODO: stub
        version = nil
        ServiceModule.initialize_module(project_idh.create_object(),ServiceMoudleName,config_agent_type,version,:no_error_if_exists=>true)
      end
      ServiceMoudleName = '.workspace'
    end
  end
end
