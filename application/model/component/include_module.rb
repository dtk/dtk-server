module DTK; class Component
  class IncludeModule < Model
    #a version context element is hash with keys: :repo,:branch,:implementation
    def self.get_version_context(component_idhs,impl_idhs)
      include_modules = get_from_component_idhs(component_idhs)
      impls = get_implementations(impl_idhs)
      #find all the needed modules and look for conflictes
      find_and_check_modele_versions(include_modules,impls)
    end

   private
    def self.get_from_component_idhs(component_idhs)
      ret = Array.new()
      return ret if component_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:module,:version_constraint],
        :filter => [:oneof,:component_id,component_idhs.map{|idh|idh.get_id()}]
      }
      incl_mod_idh = component_idhs.first.createMH(:include_module)
      get_objs(incl_mod_idh,sp_hash)
    end

    def self.get_implementations(impl_idhs)
      ret = Array.new
      return ret if impl_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:repo,:branch,:module_name,:version],
        :filter => [:oneof,:id,impl_idhs.map{|idh|idh.get_id()}]
      }
      impl_mh = impl_idhs.first.createMH()
      get_objs(impl_mh,sp_hash)
    end

    def self.find_and_check_modele_versions(include_modules,impls)
      #index by module_name to make sure no conflicts
      ndx_modules = Hash.new()
      impls.each do |impl|
        module_name = impl[:module_name]
        version = ((!impl.has_default_version?()) && impl[:version])
        if existing_module = ndx_modules[module_name]
          raise_error_if_conflict(existing_module,module_name,version)
        else
          ndx_modules[module_name] = {:version => version, :implementation => impl}
        end
      end

      info_to_lookup = Array.new
      include_modules.each do |incl_mod|
        module_name = incl_mod[:module]
        if version = incl_mod.scalar_version?()
          if existing_module = ndx_modules[module_name]
            raise_error_if_conflict(existing_module,module_name,version)
          else
            info_to_lookup << {:version => mod_info[:version],:module_name => module_name,:include_module_id => incl_mod[:id]} 
            ndx_modules[module_name] = {:version => version, :include_module => incl_mod}
          end
        else
          raise Error.new("Not implemented yet treatment of include module with constraint (#{incl_mod[:version_constraint]})")
        end
      end

      #need to look up implementation that corresponds to each included module
      ndx_impls = lookup_and_ndx_impls(info_to_lookup)

      ndx_modules.values.map{|r|version_context_form(r,ndx_impls)}
    end

    def self.raise_error_if_conflict(existing_module,module_name,version)
      unless version == existing_module[:version]
        #TODO: want this to be raised before task executed rather than error in task
        existing_version = existing_module[:version]
        raise ErrorUsage.new("Inconsistent versions for module (#{module_name}): #{version_print_form(version)}, #{version_print_form(existing_version)}")
      end
    end

    def self.version_print_form(version)
      version||'CURRENT'
    end

    def self.lookup_and_ndx_impls(info_to_lookup)
      ret = Hash.new()
      Log.error("TODO: write this routine")
      ret
    end

    def self.version_context_form(mod_info,ndx_impls)
      if impl = mod_info[:implementation]
        version_context_form_impl(impl)
      else
        ndx = mod_info[:include_module][:id]
        version_context_form_impl(ndx_impls[ndx])
      end
    end
    
    def self.version_context_form_impl(impl)
      {:repo => impl[:repo],:branch => impl[:branch], :implementation => impl[:module_name]}
    end

    def scalar_version?()
      vc = self[:version_constraint]
      vc if vc.nil? or vc.kind_of?(String)
    end

  end
end; end
