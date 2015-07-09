module DTK; class ModuleBranch
  class Location
    class Server < self
      def initialize(project, local_params = nil, remote_params = nil)
        super
      end
      class Local < Location::Local
        def self.workspace_branch_name(project, version = nil)
          ret_branch_name(project, version)
        end

        def self.private_user_repo_name(username, module_type, module_name, module_namespace)
          repo_name = "#{username}-#{module_namespace}-#{module_name}"

          case module_type
            when :service_module
              return "sm-#{repo_name}"
            when :test
              return "tm-#{repo_name}"
            else
              repo_name
            end
        end

        private

        def ret_branch_name
          self.class.ret_branch_name(@project, version())
        end

        def ret_private_user_repo_name
          username = CurrentSession.new.get_username()
          namespace_name = module_namespace_name() || Namespace.default_namespace_name
          Local.private_user_repo_name(username, @component_type, module_name(), namespace_name)
        end

        #===== helper methods

        def self.ret_branch_name(project, version)
          user_prefix = "workspace-#{project.get_field?(:ref)}"
          if version.is_a?(ModuleVersion::AssemblyModule)
            assembly_suffix = "--assembly-#{version.assembly_name}"
            "#{user_prefix}#{assembly_suffix}"
          else
            version_suffix = ((version && version != VersionFieldDefault) ? "-v#{version}" : '')
            "#{user_prefix}#{version_suffix}"
          end
        end
      end
    end
  end
end; end
