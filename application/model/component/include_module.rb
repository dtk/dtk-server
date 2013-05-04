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
      impls_to_set = Array.new
      impls_to_find = Array.new
      ret.each{|incl_mod|incl_mod.find_matching_implementation!(impls_to_set,impls_to_find,impls)}

      unless impls_to_set.empty? 
        pp [:debug,:impls_to_set,impls_to_set]
      end
      unless impls_to_find.empty? 
        pp [:debug,:impls_to_find,impls_to_find]
      end

      ret
    end

    #three posibilities
    # has :implementation set already -> no op
    # finds a match in impls -> adds to impls_to_set and upadtes self
    # finds no match -> add row to impls_to_find
    def find_matching_implementation!(impls_to_set,impls_to_find,impls)
      return if self[:implementation]
      impls.each do |impl|
        if match_implementation?(impl)
          self[:implementation_id] = impl[:id]
          self[:implementation] = impl
          impls_to_set<< {:id => self[:id], :implementation_id => impl[:id]}
          return
        end 
      end
      module_name, version = ret_module_name_and_version()
      impls_to_find << {:module_include_id => self[:id],:module_name => module_name, :version => version}
      nil
    end

    def module_name()
      get_field?(:display_name)
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
        module_name = incl_mod.module_name()
        is_scalar,version = incl_mod.scalar_version?()
        if is_scalar
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

    #returns [is_scalar,version]
    def scalar_version?()
      vc = self[:version_constraint]
      is_scalar = (vc.nil? or vc.kind_of?(String))
      [is_scalar,is_scalar && vc]
    end

    #returns [module_name,version]
    def ret_module_name_and_version()
      is_scalar,version = scalar_version?()
      unless is_scalar
        raise Error.new("Not implemented yet treatment of include module with constraint (#{self[:version_constraint]})")
      end
      [module_name(),version]
    end

    def match_implementation?(impl)
      module_name, version = ret_module_name_and_version()
      return nil unless impl[:module_name] == module_name

      impl_version = ((!impl.has_default_version?()) && impl[:version])
      if version == impl_version
        true
      else
        incl_mod_print_form = (version ? "#{module_name}:#{version}" : module_name)
        impl_print_form = (impl_version ? "#{module_name}:#{impl_version}" : module_name)
        raise ErrorUsage.new("Include module (#{incl_mod_print_form} conflicts with (#{impl_print_form})")
      end
    end

  end
end; end
