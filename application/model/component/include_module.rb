module DTK; class Component
  class IncludeModule < Model
    #a version context element is hash with keys: :repo,:branch,:implementation
    def self.get_version_context(component_idhs,impl_idhs)
      include_modules = get_from_component_idhs(component_idhs)
      impls = get_implementations(impl_idhs)
      #find all the needed modules and look for conflictes
      find_and_check_modele_versions(include_modules,impls)
    end

    def self.get_and_set_with_impls_if_can(component_idhs,impls,opts={})
      ret = Array.new()
      return ret if component_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:module,:version_constraint,:implementation],
        :filter => [:oneof,:component_id,component_idhs.map{|idh|idh.get_id()}]
      }
      incl_mod_idh = component_idhs.first.createMH(:include_module)
      ret = get_objs(incl_mod_idh,sp_hash)
      incl_rows_to_update = Array.new
      ret.each do |incl_mod|
        if update_row = incl_mod.set_matching_implementation?(impls,opts)
          incl_rows_to_update << incl_rows_to_update
        end
      end
      unless incl_rows_to_update.empty?
        pp [:debug,:incl_rows_to_update,incl_rows_to_update]
      end

      ret
    end
   private

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

    #returns id, implementation_id pair if matches and needs to be set
    def set_matching_implementation?(impls,opts={})
      ret = nil
      return ret if self[:implementation]

      impls.each do |impl|
        if match_implementation?(impl)
          self[:implementation_id] = impl[:id]
          self[:implementation] = impl
          return {:id => self[:id], :implementation_id => impl[:id]}
        end 
      end
      if opts[:raise_error_on_no_match]
        raise ErrorUsage.new("There is no component template matching include_module (#{inspect()})")
      end
      ret
    end

    def match_implementation?(impl)
      return nil if impl[:module_name] == self[:module]

      module_name = impl[:module_name]
      if version = scalar_version?()
        impl_version = ((!impl.has_default_version?()) && impl[:version])
        if version == impl_version
          true
        else
          incl_mod_print_form = (version ? "#{module_name}:#{version}" : module_name)
          impl_print_form = (impl_version ? "#{module_name}:#{impl_version}" : module_name)
          raise ErrorUsage.new("Include module (#{incl_mod_print_form} conflicts with (#{impl_print_form})")
        end
      else
        raise Error.new("Not implemented yet treatment of include module with constraint (#{incl_mod[:version_constraint]})")
      end
    end

  end
end; end
