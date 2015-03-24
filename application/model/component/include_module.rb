module DTK; class Component
  class IncludeModule < Model
    def self.common_columns()
      [:id,:group_id,:display_name,:version_constraint]
    end

    def module_name()
      get_field?(:display_name)
    end

    # For all components in components, this method returns its implementation plus 
    # does recursive anaysis to follow the components includes to find other components that must be included also
    def self.get_matching_implementations(assembly_instance,component_idhs)
      # TODO: check that  Component.get_implementations is consistent with what ModuleRefs::Lock returns
      # with respect to namespace resolution
      ret =  Component.get_implementations(component_idhs)
      include_modules = get_include_modules(component_idhs)
      return ret if include_modules.empty?()
      
      unless assembly_instance
        Log.error("Unexpected that assembly_instance is nil in IncludeModule.get_matching_implementations; not putting in includes")
        return ret
      end

      # Add to the impls in ret the ones gotten by following the include moulde links
      # using ndx_ret to get rid of duplicates
      # includes are indexed on components, so at first level get component modules, but then can only see what component modules
      # are includes using ModuleRefs::Lock
      ndx_ret = ret.inject(Hash.new){|h,impl|h.merge(impl.id => impl)}      
      locked_module_refs = ModuleRefs::Lock.get(assembly_instance)
      included_impls = locked_module_refs.matching_impls_with_children(include_modules.map{|im|im.module_name()})
      ndx_ret = included_impls.inject(ndx_ret){|h,impl|h.merge(impl.id => impl)}
      ndx_ret.values
    end

   private
    def self.get_include_modules(component_idhs)
      Component.get_include_modules(component_idhs,:cols => common_columns())
    end
  end
end; end
