module DTK; class Component
  class IncludeModule < Model
    #a version context element is hash with keys: :repo,:branch,:implementation
    def self.get_impls_for_version_context(component_idhs,impl_idhs)
      ret = get_implementations(impl_idhs)
      include_modules = get_include_mods_with_impls(component_idhs)
      include_modules.each do |incl_mod|
        if impl = incl_mod[:implementation]
          ret << impl
        else
          incl_mod.delete(:implementation) #for cosmetics when prinint in error
          raise Error.new("Unexpected that incl_mod #{incl_mod.inspect} does not have a linked implementation")
        end
      end
      ret
    end

    #this method looks for include_mosules on a component in component_idhs and sees if it s matches
    #if an include module is not set to an implementetaion it does so
    #it returns a hash that has key :error_code and then params related to error key
    def self.find_violations_and_set_impl(component_idhs,impls)
      ret = Array.new()
      return ret if component_idhs.empty?
      incl_mods = get_include_mods_with_impls(component_idhs)
      return ret if incl_mods.empty?

      impls_to_set_on_incl_mods = Array.new
      incl_mods_to_match = Array.new
      incl_mods.each{|incl_mod|incl_mod.find_matching_implementation!(ret,impls_to_set_on_incl_mods,incl_mods_to_match,impls)}

      unless incl_mods_to_match.empty? 
        impl_mh = component_idhs.first.createMH(:implementation)
        find_matching_impls!(ret,impls_to_set_on_incl_mods,impl_mh,incl_mods_to_match)
      end

      unless impls_to_set_on_incl_mods.empty? 
        #not doing updates if any errors
        if ret.empty?
          update_from_rows(incl_mod_mh,impls_to_set_on_incl_mods)
        end
      end

      ret
    end

    #three posibilities
    # has :implementation set already -> no op
    # finds a match in impls -> adds to impls_to_set_on_incl_mods and upadtes self
    # finds no match -> add row to incl_mods_to_match
    def find_matching_implementation!(ret_errors,impls_to_set_on_incl_mods,incl_mods_to_match,impls)
      return if self[:implementation]
      impls.each do |impl|
        if match_implementation?(ret_errors,impl)
          self[:implementation_id] = impl[:id]
          self[:implementation] = impl
          impls_to_set_on_incl_mods << {:id => self[:id], :implementation_id => impl[:id]}
          return
        end 
      end
      module_name, version = ret_module_name_and_version()
      incl_mods_to_match << {:id => self[:id],:module_name => module_name, :version => version}
      nil
    end

    #appropriately updates ret_errors and impls_to_set_on_incl_mods
    def self.find_matching_impls!(ret_errors,impls_to_set_on_incl_mods,impl_mh,incl_mods_to_match)
      disjuncts = incl_mods_to_match.map do |incl_mod_info|
        [:and, [:eq,:module_name,incl_mod_info[:module_name]],
         [:eq,:version,Implementation.version_field(incl_mod_info[:version])]]
      end
      filter = ((disjuncts.size == 1) ? disjuncts : ([:or] + disjuncts))
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:repo,:branch,:module_name,:version],
        :filter => filter
      }
      impls = get_objs(impl_mh,sp_hash)

      incl_mods_to_match.each  do |incl_mod_info|
        impl_match = impls.find do |impl|
          (impl[:module_name] == incl_mod_info[:module_name]) and (impl[:version] == Implementation.version_field(incl_mod_info[:version]))
        end
        if impl_match
          impls_to_set_on_incl_mods << {:id => incl_mod_info[:id], :implementation_id => impl_match[:id]}
        else
          error_el = {
            :error_code => :dangling_module_include,
            :module_name => incl_mod_info[:module_name],
            :version => incl_mod_info[:version]
          }
          ret_errors << error_el
        end
      end
      nil
    end

    def module_name()
      get_field?(:display_name)
    end

   private
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

    def self.get_include_mods_with_impls(component_idhs)
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:module,:version_constraint,:implementation],
        :filter => [:oneof,:component_id,component_idhs.map{|idh|idh.get_id()}]
      }
      incl_mod_mh = component_idhs.first.createMH(:include_module)
      get_objs(incl_mod_mh,sp_hash)
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

    def match_implementation?(ret_errors,impl)
      module_name, version = ret_module_name_and_version()
      return nil unless impl[:module_name] == module_name

      impl_version = ((!impl.has_default_version?()) && impl[:version])
      if version == impl_version
        true
      else
        error_el = {
          :error_code => :conflicting_versions,
          :module_name => module_name,
          :version => version,
          :loaded_version => impl_version 
        }
        nil
      end
    end

  end
end; end
