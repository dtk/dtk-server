module DTK
  class ModuleLocation
    class Server < self
      class Local < ModuleLocation::Local
       private
        def self.ret_local_branch(local_params)
        end
        def self.ret_repo_directory(local_params)
        end
      end
      class Remote < ModuleLocation::Remote
      end
    end
  end
end
