module DTK
  class ModuleRefs
    class Lock < Hash
      r8_nested_require('lock','element')

      def initialize(assembly_instance)
        super()
        @assembly_instance = assembly_instance
      end

      def self.get(assembly_instance)
        # TODO: this is being computed on fly; we would also like to provide persistence and also tie
        # it to a file the user can set if conflicts like a Gem.lock file
        compute(assembly_instance)
      end

      def add_matching_module_branches!() 
        ndx_els = Hash.new
        disjuncts = Array.new
        elements.each do |el|
          if impl = el.implementation
            unless el.module_branch
              disjuncts << [:and, [:eq,:repo_id,impl[:repo_id]], [:eq,:branch,impl[:branch]]]
              ndx = "#{impl[:repo_id]}:#{impl[:branch]}"
              ndx_els[ndx] = el
            end
          end
        end

        return self if disjuncts.empty?

        sp_hash = {
          :cols => ModuleBranch.common_columns(),
          :filter => [:or] + disjuncts
        }
        
        Model.get_objs(@assembly_instance.model_handle(:module_branch),sp_hash).each do |mb|
          ndx = "#{mb[:repo_id]}:#{mb[:branch]}"
          if el = ndx_els[ndx]
            el.module_branch = mb
          end
        end
        self
      end

      def matching_impls_with_children(module_names)
        ret = Array.new
        module_names.each do |module_name|
          if element = matching_element(module_name) 
            
            implementations(children_elements(element)+[element]).each do |impl|
              ret << impl unless ret.include?(impl)
            end
          end
        end
        ret
      end

     private
      def elements()
        values()
      end

      def  matching_element(module_name)
        self[module_name] || (Log.error("Unexpected that no match for module name '#{module_name}'"); nil)
      end

      def children_elements(parent_element)
        parent_element.children_module_names.map{|mn|matching_element(mn)}.compact
      end

      def implementations(elements)
        elements.map{|el|implementation(el)}.compact
      end
      def implementation(element)
        element.implementation ||
          (Log.error("Unexpected that the module '#{matching_element.namespace}:#{module_name}' does not have an corresponding implementation object"); nil)
      end

      def self.compute(assembly_instance)
        module_refs_tree = ModuleRefs::Tree.create(assembly_instance)
        collapsed = module_refs_tree.collapse()
        collapsed.choose_namespaces!()
        collapsed.add_implementations!(assembly_instance)

        collapsed.inject(new(assembly_instance)) do |h,(module_name,single_el_array)|
          if single_el_array.empty?
            Log.error("Unexpected that single_el_array is empty")
            h
          else
            if single_el_array.size > 1
              Log.error("Unexpected that single_el_array has size > 1; picking first")
            end
            h.merge(module_name => single_el_array.first)
          end
        end
      end
    end
  end
end
