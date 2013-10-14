module DTK
  class Workspace < Assembly::Instance
    def self.create?(target_idh)
      cmp_mh = target_idh.createMH(:component)
      instance_assigns = {
        :datacenter_datacenter_id => target_idh.get_id()
      }
      create_aux?(:instance,cmp_mh,instance_assigns)
    end

    def self.is_workspace?(object)
      object.kind_of?(self) or (Ref == object.get_field?(:ref))
    end

    def purge(opts={})
      self.class.delete_contents([id_handle()],opts)
      delete_tasks()
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

    def delete_tasks()
      sp_hash = {
        :cols => [:id],
        :filter => [:eq,:assembly_id,id()]
      }
      task_idhs = Model.get_objs(model_handle(:task),sp_hash)
      unless task_idhs.empty?
        Model.delete_instances(task_idhs)
      end
    end

    Ref = '__workspace'
  end
end
