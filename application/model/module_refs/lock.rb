module DTK
  class ModuleRefs
    class Lock < Hash
      r8_nested_require('lock','missing_information')

      # This object is hash of form
      #  {MODULE_NAME1 => ModuleRef::Lock,
      #   MODULE_NAME2 => ModuleRef::Lock,
      #   .... 
      # }
      attr_reader :assembly_instance
      def initialize(assembly_instance)
        super()
        @assembly_instance = assembly_instance
      end

      AllTypes = [:locked_dependencies,:locked_branch_shas]
      # opts can have keys
      #   :with_module_branches - Boolean
      #   :types subset of AllTypes
      def self.get(assembly_instance,opts={})
        types = opts[:types] || AllTypes
        opts_nested = Aux.hash_subset(opts,[:with_module_branches])
        # First check if persisted if not then compute it
        if persisted = (R8::Config[:module_refs_lock]||{})[:use_persistence] && get_module_refs_lock?(assembly_instance) 
          if missing_info = MissingInformation.missing_information?(persisted,types,opts_nested)
            missing_info.fill_in_missing_information()
          else
            persisted
          end
        else
          compute_elements(assembly_instance,types,opts_nested)
        end
      end
      
      def self.compute(assembly_instance,opts={})
        types = opts[:types] || AllTypes
        opts_nested = Aux.hash_subset(opts,[:with_module_branches])
        compute_elements(assembly_instance,types,opts)
      end


      def clear_locked_dependencies()
        ModuleRef::Lock.clear_locked_dependencies(self)
      end

      def persist()
        ModuleRef::Lock.persist(self)
        self
      end

      def matching_namespace?(module_name)
        (el = element?(module_name)) && el.namespace
      end
      def matching_locked_branch_sha?(module_name)
        (module_ref_lock = module_ref_lock(module_name)) && module_ref_lock.locked_branch_sha
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
      def self.get_module_refs_lock?(assembly_instance)
        module_ref_locks = ModuleRef::Lock.get(assembly_instance)
        unless  module_ref_locks.empty?
          module_ref_locks.inject(new(assembly_instance)) do |h,module_ref_lock|
            h.merge(module_ref_lock.module_name => module_ref_lock)
          end
        end
      end
      
      def self.compute_elements(assembly_instance,types,opts={})
        module_refs_tree = ModuleRefs::Tree.create(assembly_instance)
        collapsed = module_refs_tree.collapse(Aux.hash_subset(opts,[:raise_errors]))
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

        if types.include?(:locked_branch_shas) or opts[:with_module_branches]
          add_matching_module_branches!(ret)
        end
        if types.include?(:locked_branch_shas) 
          # requires add_matching_module_branches!(ret)
          add_locked_branch_shas!(ret)
        end

        ret
      end

      def self.add_locked_branch_shas!(locked_module_refs)
        locked_module_refs.each_pair do |module_name,module_ref_lock|
          found = false
          if el = module_ref_lock_element(module_ref_lock)
            if mb = el.module_branch
              if sha = mb[:current_sha]
                module_ref_lock.locked_branch_sha = sha
                found = true
              end
            end
          end

          unless found 
            Log.error_pp(["Unexpected that cannot find module_branch[:current_sha] for",module_name,module_ref_lock]) 
          end
        end
        locked_module_refs
      end

      def self.add_matching_module_branches!(locked_module_refs)
        ret = locked_module_refs
        ndx_els = Hash.new
        disjuncts = Array.new
        locked_module_refs.elements.each do |el|
          if impl = el.implementation
            unless el.module_branch
              disjuncts << [:and, [:eq,:repo_id,impl[:repo_id]], [:eq,:branch,impl[:branch]]]
              ndx = "#{impl[:repo_id]}:#{impl[:branch]}"
              ndx_els[ndx] = el
            end
          end
        end

        return ret if disjuncts.empty?
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:component_id,:branch,:repo_id,:current_sha,:version,:dsl_parsed],
          :filter => [:or] + disjuncts
        }
        
        mh = locked_module_refs.assembly_instance.model_handle(:module_branch)
        Model.get_objs(mh,sp_hash).each do |mb|
          ndx = "#{mb[:repo_id]}:#{mb[:branch]}"
          if el = ndx_els[ndx]
            el.module_branch = mb
          end
        end
        ret
      end
      def module_ref_lock(module_name)
        self[module_name]
      end
      def element?(module_name)
        module_ref_lock_element(module_ref_lock(module_name))
      end
      def element(module_name)
        element?(module_name) || (Log.error("Unexpected that no match for module name '#{module_name}'"); nil)
      end
      def module_ref_lock_element(module_ref_lock)
        self.class.module_ref_lock_element(module_ref_lock)
      end
      def self.module_ref_lock_element(module_ref_lock)
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