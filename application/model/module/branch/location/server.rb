module DTK; class ModuleBranch
  class Location
    class Server < self
      def initialize(project,local_params=nil,remote_params=nil)
        super
      end
      class Local < Location::Local
       private
        def self.ret_branch_name(project,local_params)
          #TODO: stub
          ModuleBranch.workspace_branch_name(project,local_params.version)
        end
        def self.ret_repo_directory(project,local_params)
        end
      end
      class Remote < Location::Remote
      end
    end
  end
end; end
