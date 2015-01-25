#TODO: see how to treat include module's implementation_id; might deprecate
module DTK
  class ModuleRefs
    # This class is used to build a hierarchical dependency tree and to detect conflicts
    class Tree 
      ModuleMappingEl = Struct.new(:model_ref,:context)
      def initialize()
        # mapping from module name to one or more ModuleMappingEls; problems indicated by having no match and more than one match 
        @module_mapping = Hash.new
      end
      private :initialize
      
      # params are assembly instance and the component instances that are in the assembly instance
      def self.create(assembly_instance,components)
        new().add_module_refs_starting_from_assembly!(assembly_instance,components)
      end

      def add_module_refs_starting_from_assembly!(assembly_instance,components)
        ret = self
        return ret if components.empty?
        
        # add component module refs associated with assembly instance
        add_assembly_instance_module_refs!(assembly_instance)

        # Find the top level component's unique module_branches
        # and compute an ndx from branches to components
        ndx_cmps = Hash.new
        components.each do |cmp|
          branch_id = cmp.get_field?(:module_branch_id)
          (ndx_cmps[branch_id] ||= Array.new) << cmp
        end
        sp_hash = {
          :cols => ModuleBranch.common_columns(),
          :filter => [:oneof,:id,ndx_cmps.keys]
        }
        cmp_module_branches = Model.get_objs(components.first.model_handle(:module_branch),sp_hash)
        recursive_add_module_refs!(cmp_module_branches,:ndx_components => ndx_cmps)
        ret
      end

      def violations?()
#long form
pp @module_mapping
        @module_mapping.each_pair do |module_name,els| 
          pp(module_name => els.map{|el|[el.context.class,el.model_ref]})
        end
        #TODO: stub
        nil
      end


     private
      def add_assembly_instance_module_refs!(assembly_instance)
        sp_hash = {
          :cols => ModuleBranch.common_columns(),
          :filter => [:eq,:id,assembly_instance.get_field?(:module_branch_id)]
        }
        service_module_branch = Model.get_obj(assembly_instance.model_handle(:module_branch),sp_hash)
        cmrs = ModuleRefs.get_component_module_refs(service_module_branch)
        add_component_module_refs!(cmrs,assembly_instance)
      end
      
      #TODO: need a way to make sure dont get in loop
      # by checking which sources covered already
      # opts can have key :ndx_components
      # which is mapping from branch_id to array of components
      # this is used to do any further prurning using include modules
      def recursive_add_module_refs!(cmp_module_branches,opts={})
        if opts[:ndx_components]
          process_component_include_modules(opts[:ndx_components].values.flatten(1))
        end
        #TODO: need to figure out how to fit this section and above
        ModuleRefs.get_multiple_component_module_refs(cmp_module_branches).each do |cmrs|
          add_component_module_refs!(cmrs,cmrs.parent)
        end
        Log.error("Not recursive yet")
      end

      def process_component_include_modules(components)
        #aug_inc_mods elements are include modules at top level and possibly the linked impementation
        component_idhs = components.map{|cmp|cmp.id_handle()}
        aug_incl_mods = Component::IncludeModule.get_include_mods_with_impls(component_idhs)
        impls = get_unique_implementations(aug_incl_mods)
        #TODO: this can be bulked up
        ndx_cmrs = impls.inject(Hash.new) do |h,impl|
          h.merge(impl[:id] => ModuleRefs.get_component_module_refs(impl.get_module_branch()))
        end

        pp [:ndx_cmrs,ndx_cmrs]
        aug_incl_mods.each do |incl_mod|
          if cmrs = ndx_cmrs[incl_mod[:implementation_id]]
            add_component_module_refs!(cmrs,incl_mod)
          end
        end
      end

      def add_component_module_refs!(cmrs,context)
        cmrs.component_modules.each_pair do |module_name,mod_ref|
          if mod_mapping_els = @module_mapping[module_name]
            mod_ref_id = mod_ref[:id]
            unless mod_mapping_els.find{|el|el.model_ref[:id] == mod_ref_id}
              @module_mapping[module_name] << module_mapping_el(mod_ref,context)
            end
          else
            @module_mapping[module_name] = [module_mapping_el(mod_ref,context)]
          end
        end
      end
      def module_mapping_el(mod_ref,context)
        ModuleMappingEl.new(mod_ref,context)
      end
      
      
      def get_unique_implementations(aug_incl_mods)
        ndx_ret = Hash.new    
        aug_incl_mods.each do |aug_incl_mod|
          unless impl = aug_incl_mod[:implementation]
            raise Error.new("need to write code when aug_incl_mod[:implementation] is nil")
          end
          ndx_ret[impl[:id]] ||= impl
        end
        ndx_ret.values
      end
      
      
    end
  end
end
