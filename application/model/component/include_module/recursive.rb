#TODO: general pattern is to use component module refs to go to next level unless have specfic components in which casew filter by
#include module
#TODO: hanlding include implementation fild not set or set inconsistently
module DTK; class Component
  class IncludeModule
    class Recursive
      ModuleMappingEl = Struct.new(:model_ref,:context)
      def initialize()
        # mapping from module name to one or more ModuleMappingEls; problems indicated by havibng no match and more than one match 
        @module_mapping = Hash.new
      end
      private :initialize
      
      # params are assembly instance and the component instances that are in the assembly instance
      #TODO: can compute this more efficiently
      def self.create_include_tree(assembly_instance,components)
        new().create_include_tree(assembly_instance,components)
      end

      def create_include_tree(assembly_instance,components)
        ret = self
        return ret if components.empty?

        # add component module refs associated with assembly instance
        add_assembly_instance_component_module_refs!(assembly_instance,components)

        # add component module refs associated top level components
        sp_hash = {
          :cols => ModuleBranch.common_columns(),
          :filter => [:oneof,:id,components.map{|cmp|cmp.get_field?(:module_branch_id)}]
        }
        Model.get_objs(components.first.model_handle(:module_branch),sp_hash).each do |cmp_module_branch|
          cmrs = ModuleRefs.get_component_module_refs(cmp_module_branch)
          add_component_module_refs!(cmrs,cmp_module_branch)
        end


        #aug_inc_mods elements are include modules at top level and possibly the linked impementation
        #TODO: this is just rough cut
        component_idhs = components.map{|cmp|cmp.id_handle()}
        aug_incl_mods = IncludeModule.get_include_mods_with_impls(component_idhs)
        reurn ret if aug_incl_mods.empty?

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
        Log.error("Not recursive yet")
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
      def add_assembly_instance_component_module_refs!(assembly_instance,components)
        if cmrs = assembly_instance_component_module_refs(assembly_instance)
          # TODO: should we prune cmrs by only including those that match at least one matching component instance
          add_component_module_refs!(cmrs,assembly_instance)
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

      def assembly_instance_component_module_refs(assembly_instance)
        ret = nil
        branches = assembly_instance.get_service_module.get_module_branches()
        unless branches.size == 1
          Log.error("Unexpected that multiple service isntance branches found")
          return ret
        end
        service_module_branch = branches.first
        ModuleRefs.get_component_module_refs(service_module_branch)
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
end; end
