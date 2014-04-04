module DTK; class ModuleBranch; class Location
  class Remote
    class DTKNCatalog < RemoteParams::DTKNCatalog
      include RemoteMixin

      def get_linked_workspace_branch_obj?(module_obj)
        filter = {
          :version => version,
          :remote_namespace => namespace
        }
        module_obj.get_augmented_workspace_branch(:filter => filter)
      end

     private
      def ret_remote_ref()
        "#{remote_repo_base}--#{namespace}"
      end
      def ret_branch_name()
        if version.nil? or version == HeadBranchName
          HeadBranchName
        else
          "v#{version}"
        end
      end
      HeadBranchName = 'master'
    end
  end
end; end; end
