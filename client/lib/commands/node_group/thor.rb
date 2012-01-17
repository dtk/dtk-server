module R8::Client
  class NodeGroupCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :description]
    end
    desc "list","List Node groups"
    def list()
      search_hash = SearchHash.new()
      search_hash.cols = self.class.pretty_print_cols()
      post rest_url("node_group/list"), search_hash.post_body_hash()
    end
  end
end

