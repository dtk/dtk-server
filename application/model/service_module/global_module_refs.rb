module DTK
  class ServiceModule
    class GlobalModelRefs
      def self.serialize_and_save_to_repo(module_info,service_module_branch)
        path = meta_filename_path()
        service_module_branch.serialize_and_save_to_repo(meta_filename_path(),ret_hash_content(module_info))
        raise Error.new("working on this")
        path
      end
     private
      def self.meta_filename_path()
        "global_module_refs.json"
      end
      def self.ret_hash_content(module_info)
        ret = SimpleOrderedHash.new()
      end
    end
  end
end
