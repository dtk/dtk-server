module DTK
  class Workspace < Assembly::Instance
    #creates both a workspace template and a workspace instance
    def self.create?(target_idh,project_idh)
      cmp_mh = target_idh.createMH(:component)
      workspace_template_idh = create_aux?(:template,cmp_mh,:project_project_id => project_idh.get_id())
      instance_assigns = {
        :datacenter_datacenter_id => target_idh.get_id(),
        :ancestor_id => workspace_template_idh.get_id()
      }
      create_aux?(:instance,cmp_mh,instance_assigns)
    end

    def self.is_workspace?(object)
      object.kind_of?(self) or (Ref == object.get_field?(:ref))
    end

   private

    def self.create_aux?(type,cmp_mh,assigns)
      match_assigns = {:ref => Ref}.merge(assigns)
      other_assigns = {
        :display_name => 'workspace',
        :description => 'Private workspace',
        :type => (type == :template) ? 'template' : 'composite'
      }
      cmp_mh_with_parent = cmp_mh.merge(:parent_model_name => (type == :template ? :project : :datacenter))
      create_from_row?(cmp_mh_with_parent,Ref,match_assigns,other_assigns)
    end
    
    Ref = '__workspace'
  end
end
