module DTK; class Component
  class IncludeModule
    class Recursive
      def initialize()
        # mapping from module name to implementations; if no conflict or missing includes 
        # then a module name wil map to a single implementation
        @module_mapping = Hash.new
      end
      def self.create_include_tree(assembly_instance,component_idhs)
        ret = new()
        unless cmrs = assembly_instance_component_module_refs(assembly_instance)
          return ret
        end
        pp [:cmrs, cmrs]
        return ret if component_idhs.empty?
        aug_incl_mods = IncludeModule.get_include_mods_with_impls(component_idhs)
pp [:aug_incl_mods,aug_incl_mods]
        ret
      end

      def process_modules!(module_branches)
      end

     private
      def self.assembly_instance_component_module_refs(assembly_instance)
        ret = nil
        branches = assembly_instance.get_service_module.get_module_branches()
        unless branches.size == 1
          Log.error("Unexpected that multiple service isntance branches found")
          return ret
        end
        service_module_branch = branches.first
        ModuleRefs.get_component_module_refs(service_module_branch)
      end

      #TODO: just for testing
      def self.component_module_refs(impl)
        ModuleRefs.get_component_module_refs(impl.get_module_branch())
      end
      def self.get_matching_stub(component_idhs)
        ret = Array.new()
        return ret if component_idhs.empty?
        aug_incl_mods = IncludeModule.get_include_mods_with_impls(component_idhs)
        return ret if aug_incl_mods.empty?

        ndx_impls = Hash.new
        aug_incl_mods.each do |r|
          if impl = r[:implementation]
            ndx_impls[impl.id] ||= impl
          end
        end

        ndx_impls.values.map do |impl|
          pp(:incl_impl => impl.hash_subset(:id,:module_name,:module_namespace,:branch),
             :component_module_refs => component_module_refs(impl).component_modules)
        end
#        impls = Component.get_implementations(component_idhs)
#        pp [:impls,impls.map{|r|r.hash_subset(:module_name,:module_namespace,:branch)}]
#        pp [:incl_impl_ids,ndx_impls.values.map{|r|r.id}]
#        pp [:impl_ids,impls.map{|r|r.id}]
#        pp [:cmp_ids,component_idhs.map{|idh|idh.get_id}]
      end
      
    end
  end
end; end
