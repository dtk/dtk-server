module DTK; class ModuleBranch
  class Location
    class RemoteParams < Params
      # keys: :module_type,:module_name,:remote_repo_base,:namespace,:version?
      def remote_repo_base
        self[:remote_repo_base]
      end

      class DTKNCatalog < self
        def create_remote(project)
          Remote::DTKNCatalog.new(project,self)
        end

        private

        def legal_keys
          [:module_type,:module_name,:remote_repo_base,:namespace,:version?]
        end
      end

      class TenantCatalog < self
        def create_remote(project)
          Remote::TenantCatalog.new(project,self)
        end

        private

        def legal_keys
          [:module_type,:module_name,:remote_repo_base,:namespace?,:version?]
        end
      end
    end

    class Remote
      def self.includes?(obj)
        obj.is_a?(DTKNCatalog) || obj.is_a?(TenantCatalog)
      end

      module RemoteMixin
        attr_reader :project
        def initialize(project,remote_params)
          super(remote_params)
          @project = project
        end

        def branch_name
          @branch_name ||= ret_branch_name()
        end

        def remote_ref
          @remote_ref ||= ret_remote_ref()
        end

        def repo_url
          @repo_url ||= ret_repo_url()
        end

        def set_repo_name!(remote_repo_name)
          if @repo_name
            raise Error.new('Not expected that @repo_name is non nil')
          end
          @repo_name = remote_repo_name
          self
        end

        def repo_name
          if @repo_name.nil?
            raise Error.new('Not expected that @repo_name is nil')
          end
          @repo_name
        end
      end
      r8_nested_require('remote','dtkn_catalog')
      r8_nested_require('remote','tenant_catalog')
    end
  end
end; end
