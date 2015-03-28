module DTK
  class ModuleRefs
    class Lock < Hash
      # This object is hash of form
      #  {MODULE_NAME1 => ModuleRef::Lock,
      #   MODULE_NAME2 => ModuleRef::Lock,
      #   .... 
      # }
      def initialize(assembly_instance)
        super()
        @assembly_instance = assembly_instance
      end

      def self.get(assembly_instance,opts={})
        # TODO: first check if persisted
        compute(assembly_instance,opts)
      end

      def self.compute(assembly_instance,opts={})
        types = opts[:types] || AllTypes
        ret = compute_elements(assembly_instance,:types => types)
      end
      AllTypes = [:elements,:locked_branch_shas]

      def persist()
        Log.error("need to write persist")
        self
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
          :cols => [:id,:group_id,:display_name,:component_id,:branch,:repo_id,:current_sha,:version,:dsl_parsed],
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

      def matching_namespace?(module_name)
        if el = element?(module_name)
          el.namespace
        end
      end

      def matching_impls_with_children(module_names)
        ret = Array.new
        module_names.each do |module_name|
          if element = element?(module_name) 
            implementations(children_elements(element)+[element]).each do |impl|
              ret << impl unless ret.include?(impl)
            end
          end
        end
        ret
      end

      def elements()
        values().map{|module_ref_lock|module_ref_lock_element(module_ref_lock)}.compact
      end

     private
      def self.compute_elements(assembly_instance,opts={})
        module_refs_tree = ModuleRefs::Tree.create(assembly_instance)
        collapsed = module_refs_tree.collapse()
        collapsed.choose_namespaces!()
        collapsed.add_implementations!(assembly_instance)
        
        ret = new(assembly_instance)
        collapsed.each_pair do |module_name,single_el_array|
          if single_el_array.empty?
            Log.error("Unexpected that single_el_array is empty")
          else
            if single_el_array.size > 1
              Log.error("Unexpected that single_el_array has size > 1; picking first")
            end
            ret[module_name] = ModuleRef::Lock.create_from_element(assembly_instance,single_el_array.first)
          end
        end
        if opts[:types].nil? or opts[:types].include?(:locked_branch_shas)
          add_locked_branch_shas!(ret)
        end
        ret
      end

      def self.add_locked_branch_shas!(locked_module_refs)
        ndx_implementations = Hash.new
        locked_module_refs.elements().each do |el|
          if impl = implementation(el)
            ndx_implementations[impl.id] = {:implementation => impl, :element => el}
          end
        end
        pp ndx_implementations
        locked_module_refs
      end

      def element?(module_name)
        module_ref_lock_element(self[module_name])
      end
      def element(module_name)
        element?(module_name) || (Log.error("Unexpected that no match for module name '#{module_name}'"); nil)
      end
      def module_ref_lock_element(module_ref_lock)
        module_ref_lock  && module_ref_lock.info
      end

      def children_elements(parent_element)
        parent_element.children_module_names.map{|mn|element?(mn)}.compact
      end

      def implementations(elements)
        elements.map{|el|self.class.implementation(el)}.compact
      end
      def self.implementation(element)
        element.implementation ||
          (Log.error("Unexpected that the module '#{element.namespace}:#{element.module_name}' does not have an corresponding implementation object"); nil)
      end

    end
  end
end
