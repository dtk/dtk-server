module DTK; class ModuleBranch
  class Location
    class Server < self
      def initialize(project,local_params=nil,remote_params=nil)
        super
      end
      class Local < Location::Local
        def self.workspace_branch_name(project,version=nil)
          ret_branch_name(project,version)
        end

       private
        def ret_branch_name()
          self.class.ret_branch_name(@project,version())
        end

        def ret_private_user_repo_name()
          # DEBUG SNIPPET >>> REMOVE <<<
          require 'ap'
          ap "Private user repo name called!!!"
          ap caller[-1..1]
          username = CurrentSession.new.get_username()
          repo_name = "#{username}-local-#{module_name()}"
          # component_type can be :service_module, :puppet or :chef
          @component_type == :service_module ? "sm-#{repo_name}" : repo_name
        end

        #===== helper methods

        def self.ret_branch_name(project,version)
           # DEBUG SNIPPET >>> REMOVE <<<
          require 'ap'
          ap "Private ret branch name called!!!"
          ap caller[-1..1]
          user_prefix = "workspace-#{project.get_field?(:ref)}"
          if version.kind_of?(ModuleVersion::AssemblyModule)
            assembly_suffix = "--assembly-#{version.assembly_name}"
            "#{user_prefix}#{assembly_suffix}"
          else
            version_suffix = ((version and version != VersionFieldDefault)?  "-v#{version}" : "")
            "#{user_prefix}#{version_suffix}"
          end
        end
      end
    end
  end
end; end
