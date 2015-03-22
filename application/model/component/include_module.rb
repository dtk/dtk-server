# TODO: think best approach is to recursively add includes or to have a new object 
# maybe better to just hang includes off of the component type as opposed to the cmponent instance
# issue is after first level 'loose includes' because just know what component module to bring in.
# so maybe have indirect ones hang off of assembly component module branches
# also may return module branches not implementations since what relly need is the branch
module DTK; class Component
  class IncludeModule < Model
    def self.common_columns()
      [:id,:group_id,:display_name,:version_constraint,:implementation_id]
    end

    def module_name()
      get_field?(:display_name)
    end

    # For all components in components, this method returns its implementation plus 
    # does recursive anaysis to follow the components includes to find other components that must be included also

    # TODO: need to determine when to clear the cached information which is stored by setting implementation_id on the
    # the includes_module objects
    def self.get_matching_impls(components,assembly_instance)
      component_idhs = components.map{|r|r.id_handle()}
      ret = impls = Component.get_implementations(component_idhs)
      include_modules = get_include_mods_with_impls(component_idhs)
      return ret if include_modules.empty?()

      # if any include_module is not linked to a implementation then find implementations for include_modules
      incl_mods_to_process = include_modules.select{|incl_mod|incl_mod[:implementation].nil?}
      unless incl_mods_to_process.empty?
        module_refs_tree = ModuleRefs::Tree.create(assembly_instance,:components => components)

        ModuleRefsTreeProcessing.new(module_refs_tree).set_implementation_on_include_modules(incl_mods_to_process)
        include_modules = get_include_mods_with_impls(component_idhs)
      end

      include_modules.each do |incl_mod|
        if impl = incl_mod[:implementation]
          ret << impl
        else
          incl_mod.delete(:implementation) #for cosmetics when printing error
          raise Error.new("Unexpected that incl_mod #{incl_mod.inspect} does not have a linked implementation")
        end
      end
      ret
    end

    # returns [module_name,version]
    def ret_module_name_and_version()
      is_scalar,version = scalar_version?()
      unless is_scalar
        raise Error.new("Not implemented yet treatment of include module with constraint (#{self[:version_constraint]})")
      end
      [module_name(),version]
    end
    
   private
    # returns [is_scalar,version]
    def scalar_version?()
      vc = self[:version_constraint]
      is_scalar = (vc.nil? or vc.kind_of?(String))
      [is_scalar,is_scalar && vc]
    end
    

    def self.get_include_mods_with_impls(component_idhs)
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:version_constraint,:implementation],
        :filter => [:oneof,:component_id,component_idhs.map{|idh|idh.get_id()}]
      }
      incl_mod_mh = component_idhs.first.createMH(:component_include_module)
      get_objs(incl_mod_mh,sp_hash)
    end

    class ModuleRefsTreeProcessing
      def initialize(module_refs_tree)
        @module_refs_tree = module_refs_tree
      end
      def set_implementation_on_include_modules(include_modules)
        # compute include mdoule info array
        incl_mods_info = Array.new
        include_modules.each do |incl_mod|
          module_name = incl_mod.module_name()
          matching_namespaces = @module_refs_tree.module_matches?(incl_mod.module_name())
          if matching_namespaces.empty?
            raise ErrorUsage.new("Cannot find namespace for module '#{module_name}'")
          else
            if matching_namespaces.size > 1
              Log.error("multiple namespaces (#{matching_namespaces.join(',')}) match when trying to disambiguate include for '#{module_name}'; picking first")
            end
            namespace = matching_namespaces.first
            version = nil
            incl_mods_info << IncludeModuleInfo.new(incl_mod.id,module_name,namespace,version)
          end
        end

        # compute implementations indexed by namespace and module name
        ndx_impls = Hash.new
        impl_mh = include_modules.first.model_handle(:implementation)
        matching_implementations(impl_mh,incl_mods_info).each do |impl|
         (ndx_impls[impl[:module_namespace]] ||= Hash.new)[impl[:module_name]] = impl
        end


        impls_to_set_on_incl_mods = Array.new
        incl_mods_info.each do |info|
          if impl = (ndx_impls[info.module_namespace]||{})[info.module_name]
            impls_to_set_on_incl_mods << {:id => info.id, :implementation_id => impl[:id]}
          else
            Log.error("Cannot find implemenenation matching '#{info.module_namespace}:#{info.module_name}'; skipping this item")
          end
        end

        # update the include rows with the implementation ids
        unless impls_to_set_on_incl_mods.empty? 
          incl_mod_mh = include_modules.first.model_handle(:component_include_module)
          IncludeModule.update_from_rows(incl_mod_mh,impls_to_set_on_incl_mods)
        end
      end

     private
      IncludeModuleInfo = Struct.new(:id,:module_name,:module_namespace,:version)
      def matching_implementations(impl_mh,incl_mods_info)
        disjuncts = incl_mods_info.map do |incl_mod_info|
          [:and, 
           [:eq,:module_name,incl_mod_info.module_name],
           [:eq,:module_namespace,incl_mod_info.module_namespace],
           [:eq,:version,Implementation.version_field(incl_mod_info.version)]]
        end
        filter = ((disjuncts.size == 1) ? disjuncts.first : ([:or] + disjuncts))
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:repo,:branch,:module_name,:module_namespace,:version],
          :filter => filter
        }
        Model.get_objs(impl_mh,sp_hash)
      end
    end

    # TODO: this is legacy and may be deprecated
    module WithoutModuleRefsTree
      # This method looks for include_modules on a component in component_idhs
      # for each include_module it finds it looks to find a matching implementation if one does not exist
      # it returns an array of hashes that has an error code and params related to error key
      def self.find_violations_and_set_impl(components,impls,incl_mods,opts={})
        ret = Array.new()
        component_idhs = components.map{|r|r.id_handle()}

        impls_to_set_on_incl_mods = Array.new
        incl_mods_to_match = Array.new
        incl_mods.each do |incl_mod|
          find_matching_implementation!(incl_mod,impls_to_set_on_incl_mods,incl_mods_to_match,impls)
        end
        
        unless incl_mods_to_match.empty? 
          impl_mh = component_idhs.first.createMH(:implementation)
          find_matching_impls!(ret,impls_to_set_on_incl_mods,impl_mh,incl_mods_to_match)
        end
        
        unless impls_to_set_on_incl_mods.empty? 
          # if ret is not empty then it will be indicating that there is an error
          # not doing updates if any errors
          if ret.empty?
            incl_mod_mh = component_idhs.first.createMH(:component_include_module)
            IncludeModule.update_from_rows(incl_mod_mh,impls_to_set_on_incl_mods)
          end
        end
        
        ret
      end

      # three posibilities
      # has :implementation set already -> no op
      # finds a match in impls -> adds to impls_to_set_on_incl_mods and upadtes self
      # finds no match -> add row to incl_mods_to_match
      def self.find_matching_implementation!(incl_mod,impls_to_set_on_incl_mods,incl_mods_to_match,impls)
        return if incl_mod[:implementation]
        impls.each do |impl|
          if match_implementation?(incl_mod,impl)
            incl_mod[:implementation_id] = impl[:id]
            incl_mod[:implementation] = impl
            impls_to_set_on_incl_mods << {:id => incl_mod[:id], :implementation_id => impl[:id]}
            return
          end 
        end
        module_name, version = incl_mod.ret_module_name_and_version()
        incl_mods_to_match << {:id => incl_mod[:id],:module_name => module_name, :version => version}
        nil
      end
      

      # appropriately updates ret_errors and impls_to_set_on_incl_mods
      def self.find_matching_impls!(ret_errors,impls_to_set_on_incl_mods,impl_mh,incl_mods_to_match)
        disjuncts = incl_mods_to_match.map do |incl_mod_info|
          [:and, [:eq,:module_name,incl_mod_info[:module_name]],
           [:eq,:version,Implementation.version_field(incl_mod_info[:version])]]
        end
        filter = ((disjuncts.size == 1) ? disjuncts.first : ([:or] + disjuncts))
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:repo,:branch,:module_name,:version],
          :filter => filter
        }
        impls = Model.get_objs(impl_mh,sp_hash)
        
        incl_mods_to_match.each  do |incl_mod_info|
          impl_matches = impls.select do |impl|
            (impl[:module_name] == incl_mod_info[:module_name]) and (impl[:version] == Implementation.version_field(incl_mod_info[:version]))
          end
          if impl_matches.size > 1
            namespaces = impl_matches.map{|r|r.get_field?(:module_namespace)}.compact
            Log.error("multiple namespaces (#{namespaces.join(',')}) match when trying to disambiguate include for '#{incl_mod_info[:module_name]}'; picking first")
          end
          
          unless impl_matches.empty?
            impls_to_set_on_incl_mods << {:id => incl_mod_info[:id], :implementation_id => impl_matches.first[:id]}
          else
            error_el = {
              :error_code  => :dangling_module_include,
              :module_name => incl_mod_info[:module_name],
              :version     => incl_mod_info[:version]
            }
            ret_errors << error_el
          end
        end
      end

      def self.match_implementation?(incl_mod,impl)
        module_name, version = incl_mod.ret_module_name_and_version()
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
  end
end; end
