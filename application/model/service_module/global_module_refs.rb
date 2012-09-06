module DTK
  class ServiceModule
    class GlobalModelRefs
      def self.serialize_and_save_to_repo(module_info,service_module_branch)
        path = meta_filename_path()
        service_module_branch.serialize_and_save_to_repo(meta_filename_path(),hash_content(module_info))
        raise Error.new("working on this")
        path
      end
     private
      def self.meta_filename_path()
        "global_module_refs.json"
      end
      def self.hash_content(module_info)
        SimpleOrderedHash.new([hash_content_component_modules(module_info),hash_content_service_modules(module_info)].compact)
      end
      def self.hash_content_component_modules(module_info)
        cmp_mods = module_info.select{|m|m.kind_of?(ComponentModule)}.sort{|a,b|a[:display_name] <=> b[:display_name]}
        return nil if cmp_mods.empty?
        component_modules = cmp_mods.inject(SimpleOrderedHash.new()) do |h,m|
          h.merge(m[:display_name] => {:namespace=> m[:repo][:remote_repo_namespace]})
        end
        {:component_modules => component_modules} 
      end
      def self.hash_content_service_modules(module_info)
        svc_mods = module_info.select{|m|m.kind_of?(ServiceModule)}.sort{|a,b|a[:display_name] <=> b[:display_name]}
        return nil if svc_mods.empty?
        raise Error.new("TODO: hash_content_component_modules processing not implemented yet")
      end
    end
  end
end
