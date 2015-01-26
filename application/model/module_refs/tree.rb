#TODO: see how to treat include module's implementation_id; might deprecate
module DTK
  class ModuleRefs
    r8_nested_require('tree','link')
    # This class is used to build a hierarchical dependency tree and to detect conflicts
    class Tree 
      attr_reader :module_branch
      def initialize(module_branch,context=nil)
        @module_branch = module_branch
        @context = context
        @links = Array.new #array of Links
      end
      private :initialize
      
      # params are assembly instance and the component instances that are in the assembly instance
      def self.create(assembly_instance,components)
        create_module_refs_starting_from_assembly(assembly_instance,components)
      end

      def violations?()
        #TODO: stub
        nil
      end
      
      def add_link!(sub_tree)
        @links << Link.new(sub_tree)
      end

      #For Aldin
      def debug_hash_form()
        ret = Hash.new
        ret[:context] = {}
        if @context.kind_of?(Assembly)
          ret[:context][:type] = 'Assembly::Instance'
          ret[:context][:name] = @context.get_field?(:display_name)
        elsif @context.kind_of?(ModuleRef)
          ret[:context][:type] = 'ModuleRef'
          ret[:context][:ref] = "#{@context[:namespace_info]}:#{@context[:module_name]}"
        else
          ret[:context][:type] = @context.class
          ret[:context][:content] = @context
        end
        @links.each do |link|
          (ret[:links] ||= Array.new) << link.tree.debug_hash_form()
        end
        ret
      end
     private
      def self.create_module_refs_starting_from_assembly(assembly_instance,components)
        # get relevant service and component module branches 
        ndx_cmps = Hash.new #components indexed (grouped) by branch id
        components.each do |cmp|
          branch_id = cmp.get_field?(:module_branch_id)
          (ndx_cmps[branch_id] ||= Array.new) << cmp
        end
        service_module_branch_id = assembly_instance.get_field?(:module_branch_id)
        sp_hash = {
          :cols => ModuleBranch.common_columns(),
          :filter => [:or, [:eq,:id,service_module_branch_id],[:oneof,:id,ndx_cmps.keys]]
        }
        relevant_module_branches = Model.get_objs(assembly_instance.model_handle(:module_branch),sp_hash)
        service_module_branch = relevant_module_branches.find{|r|r[:id] == service_module_branch_id}
        cmp_module_branches   = relevant_module_branches.reject!{|r|r[:id] == service_module_branch_id}

        ret = new(service_module_branch,assembly_instance)
        leaves = Array.new
        get_children([service_module_branch],:next_level_branches => cmp_module_branches).each do |child|
          leaves << child
          ret.add_link!(child)
        end
        recursive_add_module_refs!(ret,leaves)
        ret
      end

      def self.recursive_add_module_refs!(top,subtrees)
        return if subtrees.empty?
        leaves = Array.new
        #TODO: can bulk up
        subtrees.each do |subtree|
          get_children([subtree.module_branch]).each do |child|
            leaves << child
            subtree.add_link!(child)
          end
        end
        recursive_add_module_refs!(top,leaves)
      end

      def self.get_children(module_branches,opts={})
        ret = Array.new
        
        ndx_module_refs = Hash.new
        ModuleRefs.get_multiple_component_module_refs(module_branches).each do |cmrs|
          cmrs.component_modules.each_value do |module_ref|
            ndx_module_refs[module_ref[:id]] ||= module_ref
          end
        end
        module_refs = ndx_module_refs.values

        ndx_mod_name_branches = ndx_mod_ref_branches = nil
        if next_level_branches = opts[:next_level_branches]
          #TODO: can bulk up getting this info
          ndx_mod_name_branches = next_level_branches.inject(Hash.new) do |h,module_branch|
            h.merge(module_branch.get_module()[:display_name] => module_branch)
          end
        else
          ndx_mod_ref_branches = Hash.new
          ModuleRef.find_ndx_matching_component_modules(module_refs).each_pair do |mod_ref_id,cmp_module|
            version = nil #TODO: stub; need to change when treat service isnatnce branches
            ndx_mod_ref_branches[mod_ref_id] = cmp_module.get_module_branch_matching_version(version)
          end
        end
        # either ndx_mod_name_branches or ndx_mod_ref_branches wil be non null
        module_refs.each do |module_ref|
          matching_branch = nil
          if ndx_mod_name_branches
            unless matching_branch = ndx_mod_name_branches[module_ref[:module_name]]
              Log.error("No match for #{module_name} in #{ndx_branches.inspect}")
            end
          elsif ndx_mod_ref_branches
            unless matching_branch = ndx_mod_ref_branches[module_ref.id]
              Log.error("No match for #{module_ref.inspect} in #{ndx_mod_ref_branches}")
            end
          else
            Log.error("Unexpected that both ndx_mod_name_branches and ndx_mod_ref_branches re nil")
          end
          if matching_branch
            ret << new(matching_branch,module_ref)
          end
        end
        ret
      end

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
