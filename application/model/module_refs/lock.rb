# TODO: this is being computed on fly; we would also like to provide persistence and also tie
# it to a file teh user can set if conflicts like a Gem.lock file
module DTK
  class ModuleRefs
    class Lock < Hash
      r8_nested_require('lock','element')
      def self.compute(assembly_instance)
        module_refs_tree = ModuleRefs::Tree.create(assembly_instance)
        collapsed = module_refs_tree.collapse()
        collapsed.choose_namespaces!()
        collapsed.add_implementations!(assembly_instance)

        collapsed.inject(new()) do |h,(module_name,single_el_array)|
          if single_el_array.empty?
            Log.error("Unexpected that single_el_array is empty")
            h
          else
            if single_el_array.size > 1
              Log.error("Unexpected that single_el_array has size > 1; pikcing first")
            end
            h.merge(module_name => single_el_array.first)
          end
        end
      end
    end
  end
end
