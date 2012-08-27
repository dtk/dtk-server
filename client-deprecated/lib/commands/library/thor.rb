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
  end
end

