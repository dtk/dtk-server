module XYZ
  class RepoManagerGitService < RepoManager
#    extend RepoGitManageClassMixin
#TODO: need to repace below
    def get_file_content(file_asset)
      ret = nil
      checkout(@branch) do
        ret = File.open(file_asset[:path]){|f|f.read}
      end
      ret
    end

    private
     def initialize(path,branch,opts={})
      @branch = branch 
      @path = path
     end
  end
end
