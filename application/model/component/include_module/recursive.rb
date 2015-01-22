module DTK; class Component
  class IncludeModule
    class Recursive
      def initialize(parent)
        @parent = parent
        # mappoing from module name to implementations
        @module_mapping = Hash.new
      end
      def process_components!(components)
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
