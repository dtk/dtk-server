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
   private
    def self.create_aux?(type,cmp_mh,assigns)
      match_assigns = {:ref => Ref}.merge(assigns)
      other_assigns = {
        :display_name => 'workspace',
        :description => 'Private workspace',
        :type => (type == :template) ? 'template' : 'composite'
      }
      create_from_row?(cmp_mh,Ref,match_assigns,other_assigns)
    end
    
    Ref = '__workspace'
  end
end
