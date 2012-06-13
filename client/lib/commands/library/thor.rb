module DTK::Client
  class LibraryCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :description]
    end
    desc "list","List libraries"
    def list()
      search_hash = SearchHash.new()
      search_hash.cols = pretty_print_cols()
      post rest_url("library/list"), search_hash.post_body_hash()
    end

    desc "bind_to_repo_manager", "Bind to DTK Repo Manager"
    def bind_to_repo_manager()
      post rest_url("library/bind_to_repo_manager")
    end
  end
end

