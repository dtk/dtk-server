module DTK::Client
  class RepoCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id]
    end
    desc "list","List repos"
    def list()
      search_hash = SearchHash.new()
      search_hash.cols = pretty_print_cols()
      post rest_url("repo/list"), search_hash.post_body_hash()
    end

    desc "delete REPO-ID", "Delete repo"
    def delete(repo_id)
      post_body_hash = {:repo_id => repo_id}
      post rest_url("repo/delete"),post_body_hash
    end

    desc "sync REPO-ID", "Synchronize target repo from actual files"
    def sync(repo_id)
      post_body_hash = {:repo_id => repo_id}
      post rest_url("repo/synchronize_target_repo"),post_body_hash
    end

  end
end

