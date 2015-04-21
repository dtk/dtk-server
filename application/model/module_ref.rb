module DTK
  class ModuleRef < Model
    r8_nested_require('module_ref','version_info')
    r8_nested_require('module_ref','lock')
    r8_nested_require('module_ref','missing')

    def self.common_columns()
      [:id,:display_name,:group_id,:module_name,:module_type,:version_info,:namespace_info,:external_ref,:branch_id]
    end

    def self.reify(mh,object)
      mr_mh = mh.createMH(:model_ref)
      ret = version_info = nil
      if object.kind_of?(ModuleRef)
        ret = object
        version_info = VersionInfo::Assignment.reify?(object)
      else #object.kind_of?(Hash)  
        ret = ModuleRef.create_stub(mr_mh,object)
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

    def self.find_ndx_matching_component_modules(cmp_module_refs)
      ret = Hash.new
      return ret if cmp_module_refs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:namespace_id,:namespace],
        :filter => [:or] + cmp_module_refs.map{|r|[:eq,:display_name,r[:module_name]]}
      }
      cmp_modules = get_objs(cmp_module_refs.first.model_handle(:component_module),sp_hash)
      cmp_module_refs.each do |cmr|
        module_name = cmr[:module_name]
        namespace = cmr.namespace
        if cmp_module = cmp_modules.find{|mod|mod[:display_name] == module_name and (mod[:namespace]||{})[:display_name] == namespace}
          ret[cmr[:id]] = cmp_module
        end
      end
      ret
    end

    # this finds for each mocule branch the array of component model ref objects associated with the branch
    def self.get_ndx_component_module_ref_arrays(branches)
      ret = Hash.new
      return ret if branches.empty?
      sp_hash = {
        :cols => common_columns()+[:branch_id],
        :filter => [:oneof,:branch_id,branches.map{|r|r.id()}]
      }
      mh = branches.first.model_handle(:module_ref)
      get_objs(mh,sp_hash).each do |r|
        (ret[r[:branch_id]] ||= Array.new) << r
      end
      ret
    end
    def self.get_component_module_ref_array(branch)
      sp_hash = {
        :cols => common_columns(),
        :filter => [:eq,:branch_id,branch.id()]
      }
      mh = branch.model_handle(:module_ref)
      get_objs(mh,sp_hash)
    end

    def self.create_or_update(parent,module_ref_hash_array)
      update(:create_or_update,parent,module_ref_hash_array)
    end

    def self.update(operation,parent,module_ref_hash_array)
      return if module_ref_hash_array.empty? and operation == :add
      rows = ret_create_rows(parent,module_ref_hash_array)
      model_handle = parent.model_handle.create_childMH(:module_ref)
      case operation
       when :create_or_update
        matching_cols = [:module_name]
        modify_children_from_rows(model_handle,parent.id_handle(),rows,matching_cols,:update_matching => true)
       when :add
        create_from_rows(model_handle,rows)
       else
        raise Error.new("Unexpected operation (#{operation})")
      end
    end

    def version_string()
      self[:version_info] && self[:version_info].version_string()
    end

    def namespace()
      unless self[:namespace_info].nil?
        if self[:namespace_info].kind_of?(String)
          self[:namespace_info]
        else
          raise Error.new("Unexpected type in namespace_info: #{self[:namespace_info].class}")
        end
      end
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
    DSLHashCols = [:version_info,{:namespace_info => :namespace},:external_ref]

   private
    def self.ret_create_rows(parent,module_ref_hash_array)
      ret = Array.new
      return ret if module_ref_hash_array.empty?
      parent_id_assigns = {
        parent.parent_id_field_name(:module_ref) => parent.id()
      }
      module_ref_hash_array.map do |module_ref_hash|
        assigns = 
          if version_info = module_ref_hash[:version_info]
            parent_id_assigns.merge(:version_info => version_info.to_s)
          else
            assigns = parent_id_assigns
          end
        el = Aux.hash_subset(module_ref_hash,[:ref,:display_name,:module_name,:module_type,:namespace_info,:external_ref]).merge(assigns)
        el[:display_name] ||= display_name(el)
        el[:ref] ||= ref(el)
        el
      end
    end

    def self.display_name(module_ref_hash)
      [:module_name].each do |key|
        if module_ref_hash[key].nil?
          raise Error.new("Unexpected that module_ref_hash[#{key}] is nil")
        end
      end
      module_ref_hash[:module_name]
    end
    
    def self.ref(module_ref_hash)
      [:module_type,:module_name].each do |key|
        if module_ref_hash[key].nil?
          raise Error.new("Unexpected that module_ref_hash[#{key}] is nil")
        end
      end
      "#{module_ref_hash[:module_type]}--#{module_ref_hash[:module_name]}"
    end
  end
end
