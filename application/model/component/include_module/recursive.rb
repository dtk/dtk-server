module DTK; class Component
  class IncludeModule
    class Recursive
      def initialize()
        # mapping from module name to implementations; if no conflict or missing includes 
        # then a module name wil map to a single implementation
        @module_mapping = Hash.new
      end
      # params are assembly insatnce and the component instances that are in the assembly isnatnce
      # the method looks at all its include modules and for each it comparese this to
      def self.create_include_tree(assembly_instance,components)
        ret = new()
        return ret if components.empty?
        component_idhs = components.map{|r|r.id_handle()}
        if cmrs = assembly_instance_component_module_refs(assembly_instance)
          # TODO: should we prune cmrs by only including those that has at least one matching component insatnce
          ret.add_component_module_refs!(cmrs)
        end

        aug_incl_mods = IncludeModule.get_include_mods_with_impls(component_idhs)
pp(:cmps => components,:aug_incl_mods => aug_incl_mods,:cmrs => cmrs)
        ret
      end

      def add_component_module_refs!(cmrs)
      end

      def violations?()
        #TODO: stub
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
