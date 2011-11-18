module XYZ
  module RepoGitCreateAndDeleteClassMixin
    def get_all_repos()
      Dir.chdir(R8::EnvironmentConfig::CoreCookbooksRoot) do
        Dir["*"].reject{|item|File.file?(item)}
      end
    end
  end
end
