module DTK
  class ModuleRefs
    # This class is used to build a hierarchical dependency tree and to detect conflicts
    class Tree 
      attr_reader :module_branch
      def initialize(module_branch,context=nil)
        @module_branch = module_branch
        @context = context
        # module_refs is hash where key is module_name and
        # value is either nil for a missing reference
        # or it points to a Tree object
        @module_refs = Hash.new 
      end
      private :initialize
      
      # params are assembly instance and the component instances that are in the assembly instance
      def self.create(assembly_instance, assembly_branch, components)
        create_module_refs_starting_from_assembly(assembly_instance,assembly_branch,components)
      end

      def violations?()
        missing   = Array.new
        multi_ns  = Hash.new
        refs      = hash_form()

        refs.each do |k,v|
          if k == :refs
            check_refs(v, missing, multi_ns)
          end
        end

        multi_ns.delete_if{|k,v| v.size < 2}
        return missing, multi_ns
      end

      def check_refs(refs, missing, multi_ns)
        return unless refs

        refs.each do |name,ref|
          if ref
            if val = multi_ns["#{name}"]
              namespace = ref[:namespace]
              unless val.include?(namespace)
                val << namespace
                multi_ns.merge!(name => val)
              end
            else
              multi_ns.merge!(name => [ref[:namespace]])
            end
            check_refs(ref[:refs], missing, multi_ns) if ref.has_key?(:refs)
          else
            missing << name
          end
        end
      end


      # opts[:stratagy] can be
      # - :stop_if_top_level_match (default)
      # - :find_all_matches
      def module_matches?(module_name,opts={})
        ret = Array.new
        strategy = opts[:strategy] || DefaultStratagy
        @module_refs.each_pair do |ref_module_name,subtree|
          if module_name == ref_module_name
            if namespace = subtree.namespace?() 
              ret << namespace unless ret.include?(namespace)
              if strategy == :stop_if_top_level_match
                return ret
              end
            else
              Log.error("Unexpected that no namespace info")
            end
          end
          if subtree
            subtree.module_matches?(module_name,:strategy => :find_all_matches).each do |namespace|
              ret << namespace unless ret.include?(namespace)
            end
          end
        end
        ret
      end
      DefaultStratagy = :stop_if_top_level_match

      def namespace?()
        if @context.kind_of?(ModuleRef)
          (@context||{})[:namespace_info]
        end
      end
      
      def hash_form()
        ret = Hash.new
        if @context.kind_of?(Assembly)
          ret[:type] = Workspace.is_workspace?(@context) ? 'Workspace' : 'Assembly::Instance'
          ret[:name] = @context.get_field?(:display_name)
        elsif @context.kind_of?(ModuleRef)
          ret[:type] = 'ModuleRef'
          ret[:namespace] = @context[:namespace_info]
        else
          ret[:type] = @context.class
          ret[:content] = @context
        end
        
        refs = @module_refs.inject(Hash.new) do |h,(module_name,subtree)|
          h.merge(module_name => subtree && subtree.hash_form())
        end
        ret[:refs] = refs unless refs.empty?

        ret
      end

      def add_module_ref!(module_name,child)
        @module_refs[module_name] = child
      end

     private

      def self.create_module_refs_starting_from_assembly(assembly_instance,assembly_branch,components)
        # get relevant service and component module branches 
        ndx_cmps = Hash.new #components indexed (grouped) by branch id
        components.each do |cmp|
          unless branch_id = cmp.get_field?(:module_branch_id)
            Log.error("Unexpected that :module_branch_id not in: #{cmp.inspect}")
            next
          end
          (ndx_cmps[branch_id] ||= Array.new) << cmp
        end
        cmp_module_branch_ids = ndx_cmps.keys

        sp_hash = {
          :cols => ModuleBranch.common_columns(),
          :filter => [:oneof,:id,cmp_module_branch_ids]
        }
        cmp_module_branches = Model.get_objs(assembly_instance.model_handle(:module_branch),sp_hash)

        #TODO: extra check we can remove after we refine
        missing_branches = cmp_module_branch_ids - cmp_module_branches.map{|r|r[:id]} 
        unless missing_branches.empty?
          Log.error("Unexpected that the following branches dont exist; branches with ids #{missing_branches.join(',')}") 
        end
        
        ret = new(assembly_branch,assembly_instance)
        leaves = Array.new
        get_top_level_children(cmp_module_branches,assembly_branch) do |module_name,child|
          leaves << child if child
          ret.add_module_ref!(module_name,child)
        end
        recursive_add_module_refs!(ret,leaves)
        ret
      end

      def self.recursive_add_module_refs!(top,subtrees)
        return if subtrees.empty?
        leaves = Array.new
        #TODO: can bulk up
        subtrees.each do |subtree|
          get_children([subtree.module_branch]) do |module_name,namespace,child|
            if subtree && child
              raise ErrorUsage.new("Module '#{namespace}:#{module_name}' cannot have itself listed as dependency") if subtree.module_branch == child.module_branch 
            end
            leaves << child if child
            subtree.add_module_ref!(module_name,child)
          end
        end
        recursive_add_module_refs!(top,leaves)
      end

      # TODO: fix this up because cmp_module_branches already has implict namespace so this is 
      # effectively just checking consistency of component module refs
      # and setting of module_branch_id in component insatnces
      def self.get_top_level_children(cmp_module_branches,service_module_branch,&block)
        # get component module refs indexed by module name
        ndx_module_refs = Hash.new
        ModuleRefs.get_component_module_refs(service_module_branch).component_modules.each_value do |module_ref|
          ndx_module_refs[module_ref[:module_name]] ||= module_ref
        end
    
        # get branches indexed by module_name
        # TODO: can bulk up; look also at using 
        # assembly_instance.get_objs(:cols=> [:instance_component_module_branches])
        ndx_mod_name_branches = cmp_module_branches.inject(Hash.new) do |h,module_branch|
          h.merge(module_branch.get_module()[:display_name] => module_branch)
        end
        
        ndx_mod_name_branches.each_pair do |module_name,module_branch| 
          module_ref = ndx_module_refs[module_name] 
          child = module_ref && new(module_branch,module_ref)
          block.call(module_name,child)
        end
      end

      # TODO: use opts to pass in specfic components and then ise that to us einclude modules to 
      # prune what is relevant
      def self.get_children(module_branches,opts={},&block)
        # get component module refs indexed by module name
        ndx_module_refs = Hash.new
        ModuleRefs.get_multiple_component_module_refs(module_branches).each do |cmrs|
          cmrs.component_modules.each_value do |module_ref|
            ndx_module_refs[module_ref[:id]] ||= module_ref
          end
        end
        module_refs = ndx_module_refs.values

        #ndx_module_branches is compinet module branches indexed by module ref id
        ndx_module_branches = Hash.new
        ModuleRef.find_ndx_matching_component_modules(module_refs).each_pair do |mod_ref_id,cmp_module|
          version = nil #TODO: stub; need to change when treat service isnatnce branches
          ndx_module_branches[mod_ref_id] = cmp_module.get_module_branch_matching_version(version)
        end

        module_refs.each do |module_ref|
          module_branch = ndx_module_branches[module_ref[:id]]
          child = module_branch && new(module_branch,module_ref)
          block.call(module_ref[:module_name],module_ref[:namespace_info],child)
        end
      end

    end
  end
end
=begin
      # TODO: old methods that can be helpful if looking to use includes
      def process_component_include_modules(components)
        #aug_inc_mods elements are include modules at top level and possibly the linked impementation
        component_idhs = components.map{|cmp|cmp.id_handle()}
        aug_incl_mods = Component::IncludeModule.get_include_mods_with_impls(component_idhs)
        impls = get_unique_implementations(aug_incl_mods)
        #TODO: this can be bulked up
        ndx_cmrs = impls.inject(Hash.new) do |h,impl|
          h.merge(impl[:id] => ModuleRefs.get_component_module_refs(impl.get_module_branch()))
        end

        aug_incl_mods.each do |incl_mod|
          if cmrs = ndx_cmrs[incl_mod[:implementation_id]]
            add_component_module_refs!(cmrs,incl_mod)
          end
        end
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
=end
