module DTK
  class ModuleRef < Model
    r8_nested_require('module_ref','version_info')

    def self.common_columns()
      [:id,:display_name,:group_id,:module_name,:version_info,:namespace_info]
    end

    def self.reify(mh,object)
      cmr_mh = mh.createMH(:component_model_ref)
      ret = version_info = nil
      if object.kind_of?(ModuleRef)
        ret = object
        version_info = VersionInfo::Assignment.reify?(object)
      else #object.kind_of?(Hash)  
        ret = ModuleRef.create_stub(cmr_mh,object)
        if v = object[:version_info]
          version_info = VersionInfo::Assignment.reify?(v)
        end
      end
      version_info ? ret.merge(:version_info => version_info) : ret
    end

    def set_module_version(version)
      merge!(:version_info => VersionInfo::Assignment.reify?(version))
      self
    end

    def self.get_component_module_refs(branch)
      sp_hash = {
        :cols => common_columns(),
        :filter => [:eq,:branch_id,branch.id()]
      }
      mh = branch.model_handle(:module_ref)
      get_objs(mh,sp_hash)
    end

    def self.create_or_update(parent,component_module_refs)
      return if component_module_refs.empty?
      parent_id_assigns = {
        parent.parent_id_field_name(:module_ref) => parent.id()
      }
      rows = component_module_refs.values.map do |cmr_hash|
        assigns = 
          if version_info = cmr_hash[:version_info]
            parent_id_assigns.merge(:version_info => version_info.to_s)
          else
            assigns = parent_id_assigns
          end
        Aux.hash_subset(cmr_hash,[:module_name,:namespace_info]).merge(assigns)
      end
      model_handle = parent.model_handle(:module_ref)
      matching_cols = [:module_name]
      modify_children_from_rows(model_handle,parent.id_handle(),rows,matching_cols,:update_matching => true)
    end

    def version_string()
      self[:version_info] && self[:version_info].version_string()
    end

    def dsl_hash_form()
      ret = Aux.hash_subset(self,DSLHashCols,:only_non_nil=>true) 
      if version_string = version_string()
        ret.merge!(:version_info => version_string)
      end
      if ret[:version_info] and ret[:namespace_info].nil?
        return ret[:version_info] # simple form
      end
      ret
    end
    DSLHashCols = [:version_info,{:namespace_info => :namespace}]
  end
end
