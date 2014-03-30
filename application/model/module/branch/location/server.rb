module DTK; class ModuleBranch
  class Location
    class Server < self
      def initialize(local_params=nil,remote_params=nil)
        super
      end
      class Local < Location::Local
       private
        def self.ret_local_branch(local_params)
        end
        def self.ret_repo_directory(local_params)
        end
      end
      class Remote < Location::Remote
      end
    end
  end
end; end
