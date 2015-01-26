#TODO: see how to treat include module's implementation_id; might deprecate
module DTK
  class ModuleRefs
    r8_nested_require('tree','link')
    # This class is used to build a hierarchical dependency tree and to detect conflicts
    class Tree 
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
#long form
pp @module_mapping

        nil
      end
      
      def add_link!(sub_tree)
        @links << Link.new(sub_tree)
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
        get_module_refs_and_branches([service_module_branch],:next_level_branches => cmp_module_branches).each do |r|
          child = new(r[:module_branch],r[:module_ref])
          ret.add_link!(child)
        end

        ret
      end

      # returns array of hashes with keys
      # module_ref
      # module_branch
      def self.get_module_refs_and_branches(module_branches,opts={})
        ret = Array.new
        unless next_level_branches = opts[:next_level_branches]
          raise Error.new("need to write code where we can work without this info")
        end
        #TODO: can bulk up getting this info
        ndx_branches = next_level_branches.inject(Hash.new) do |h,module_branch|
          h.merge(module_branch.get_module()[:display_name] => module_branch)
        end
        ModuleRefs.get_multiple_component_module_refs(module_branches).each do |cmrs|
          cmrs.component_modules.each_pair do |module_name,module_ref|
            unless matching_branch = ndx_branches[module_name.to_s]
              Log.error("No match for #{module_name} in #{ndx_branches.inspect}")
              next
            end
            ret << {:module_branch => matching_branch, :module_ref => module_ref} 
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

        pp [:ndx_cmrs,ndx_cmrs]
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
