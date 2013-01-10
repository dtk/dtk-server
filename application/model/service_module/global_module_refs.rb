module DTK
  class ServiceModule
    class GlobalModelRefs
      def self.serialize_and_save_to_repo(module_info,service_module_branch)
        path = meta_filename_path()
        service_module_branch.serialize_and_save_to_repo(meta_filename_path(),hash_content(service_module_branch))
        path
      end
     private
      def self.meta_filename_path()
        "global_module_refs.json"
      end

      def self.hash_content(service_module_branch)
        ret = SimpleOrderedHash.new()
        vconstraints = service_module_branch.get_module_version_constraints()
        unorderd_hash = vconstraints.constraints_in_hash_form()
        if unorderd_hash.empty?
          return ret
        end
        unless unorderd_hash.size == 1 and unorderd_hash.keys.first == :component_modules
          raise Error.new("Unexpected key(s) in module_version_constraints (#{unorderd_hash.keys.join(',')})")
        end

        cmp_mods = unorderd_hash[:component_modules]
        cmp_mod_contraints = cmp_mods.keys.to_s.sort().inject(SimpleOrderedHash.new()){|h,k|h.merge(k => cmp_mods[k.to_sym])}
        ret.merge(:component_modules => cmp_mod_contraints)
      end

    end
  end
end
