# TODO: first we can create on the fly and then we can handle persisting; we will create by
# getting the whole locked set, the object that gets persisted, and then given set of components we filter out what is not relevant 
module DTK
  class ModuleRefs
    class Lock
      def self.compute(assembly_instance)
        module_refs_tree = ModuleRefs::Tree.create(assembly_instance)
        collapsed = module_refs_tree.collapse()
        collapsed.choose_namespaces!()
        collapsed.add_implementations!(assembly_instance)
        
      end
    end
  end
end
