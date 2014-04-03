module DTK; class ModuleBranch
  class Location
    class RemoteParams < Params
      #keys: :module_type,:module_name,:remote_repo_base,:namespace,:version?
      def remote_repo_base()
        self[:remote_repo_base]
      end

      class DTKN < self
        def create_remote(project)
          Remote::DTKN.new(project,self)
        end
       private
        def legal_keys()
          [:module_type,:module_name,:remote_repo_base,:namespace,:version?]
        end
      end

      class TenantRepo < self
        def create_remote(project)
          Remote::TenantRepo.new(project,self)
        end
       private
        def legal_keys()
          [:module_type,:module_name,:remote_repo_base,:namespace?,:version?]
        end
      end
    end

    class Remote
      def self.includes?(obj)
        obj.kind_of?(DTKN) or obj.kind_of?(TenantRepo)
      end

      module RemoteMixin
        attr_reader :project
        def initialize(project,remote_params)
          super(remote_params)
          @project = project
        end
        def branch_name()
          @branch_name ||= ret_branch_name()
        end
        def remote_ref()
          @remote_ref ||= ret_remote_ref()
        end
      end
      r8_nested_require('remote','dtkn')
    end
  end
end; end

