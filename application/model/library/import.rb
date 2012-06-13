module DTK
  module LibraryImportMixin
    def bind_to_repo_manager()
      repos = RepoManager.get_repos()
      pp repos
      nil
      #TODO: stub
    end

    def import_from_repo_manager(repo_manager_hostname)
      #TODO: stub
    end
  end
end
