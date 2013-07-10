module DTK
  class ComponentModuleRef < Model
    r8_nested_require('component_module_ref','version_info')

    def self.get_component_module_refs(branch)
      sp_hash = {
        :cols => [:id,:display_name,:group_id,:component_module,:version_info,:remote_info],
        :filter => [:eq,:branch_id,branch.id()]
      }
      mh = branch.model_handle(:component_module_ref)
      get_objs(mh,sp_hash)
    end

    def self.create_or_update(parent,component_module_refs)
      return if component_module_refs.empty?
      parent_id_assigns = {
        parent.parent_id_field_name(:component_module_ref) => parent.id()
      }
      rows = component_module_refs.values.map do |cmr_hash|
        assigns = 
          if version_info = cmr_hash[:version_info]
            parent_id_assigns.merge(:version_info => version_info.to_s)
          else
            assigns = parent_id_assigns
          end
        Aux.hash_subset(cmr_hash,[:component_module,:remote_info]).merge(assigns)
      end
      model_handle = parent.model_handle(:component_module_ref)
      matching_cols = [:component_module]
      modify_children_from_rows(model_handle,parent.id_handle(),rows,matching_cols,:update_matching => true)
    end

    def version_string()
      self[:version_info] && self[:version_info].version_string()
    end
  end
end
