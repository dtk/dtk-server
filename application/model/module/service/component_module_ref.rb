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
      parent_id_assign = {
        parent.parent_id_field_name(:component_module_ref) => parent.id()
      }
      rows = component_module_refs.map do |cmp_mod_ref,content|
        if content.kind_of?(VersionInfo::Assignment)
          {
            :component_module => cmp_mod_ref.to_s, 
            :version_info => content.to_s()
          }.merge(parent_id_assign)
        else
          raise Error.new("Not treated yet component module ref content other than VersionInfo::Assignment")
        end
      end
      model_handle = parent.model_handle(:component_module_ref)
      matching_cols = [:component_module]
      modify_children_from_rows(model_handle,parent.id_handle(),rows,matching_cols,:update_matching => true)
    end
  end
end
