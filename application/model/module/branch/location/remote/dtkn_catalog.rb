module DTK; class ModuleBranch; class Location
  class Remote
    class DTKNCatalog < RemoteParams::DTKNCatalog
      include RemoteMixin
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
