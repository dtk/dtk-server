module DTK::Client
  class ProjectCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :description]
    end
    desc "list","List projects"
    def list()
      search_hash = SearchHash.new()
      search_hash.cols = pretty_print_cols()
      post rest_url("project/list"), search_hash.post_body_hash()
    end
  end
end

