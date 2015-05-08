module DTK; class Target
  class Instance
    module DefaultTarget
      def self.get(target_mh,cols=[]) 
        cols = [:id,:display_name,:group_id] if cols.empty?
        sp_hash = {
          :cols => cols,
          :filter => [:eq,:is_default_target,true]
        }
        ret = Target::Instance.get_obj(target_mh,sp_hash)
        ret && ret.create_subclass_obj(:target_instance)
      end
      
      # returns current_default_target
      # opts can be
      #   :current_default_target (computed already)
      #   :update_workspace_target  
      def self.set(target,opts={})
        ret = current_default_target = opts[:current_default_target] || get(target.model_handle(),[:display_name])
        return ret unless target
          
        if current_default_target && (current_default_target.id == target.id)
          raise ErrorUsage::Warning.new("Default target is already set to #{current_default_target[:display_name]}")
        end
        
        Model.Transaction do
          current_default_target.update(:is_default_target => false) if current_default_target
          target.update(:is_default_target => true)
          if opts[:update_workspace_target]
            # also set the workspace with this target
            Workspace.set_target(target,:mode => :from_set_default_target)
          end
        end
        ret
      end
    end
  end
end; end
