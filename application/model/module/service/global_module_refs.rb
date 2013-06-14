module DTK
  class ServiceModule
    class GlobalModuleRefs
      def self.serialize_and_save_to_repo(service_module_branch)
        path = meta_filename_path()
        service_module_branch.serialize_and_save_to_repo(meta_filename_path(),get_hash_content(service_module_branch))
        path
      end

      def self.meta_filename_path()
        "global_module_refs.json"
      end

     private
      def self.get_hash_content(service_module_branch)
        ret = SimpleOrderedHash.new()
        vconstraints = service_module_branch.get_module_global_refs()
        unordered_hash = vconstraints.constraints_in_hash_form()
        if unordered_hash.empty?
          return ret
        end
        unless unordered_hash.size == 1 and unordered_hash.keys.first == :component_modules
          raise Error.new("Unexpected key(s) in module_global_refs (#{unordered_hash.keys.join(',')})")
        end

        cmp_mods = unordered_hash[:component_modules]
        cmp_mod_contraints = cmp_mods.keys.map{|x|x.to_s}.sort().inject(SimpleOrderedHash.new()){|h,k|h.merge(k => cmp_mods[k.to_sym])}
        ret.merge(:component_modules => cmp_mod_contraints)
      end

    end
  end
end
