module R8::Client
  class StateChangeCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name,:type,:id,:change]
    end
    desc "list","List pending state changes"
    def list()
      search_hash = SearchHash.new()
      add_cols = [:object_type,:status,:node_node_id]
      search_hash.cols = pretty_print_cols() + add_cols
      search_hash.filter = [:eq, ":status", "pending"]
      post rest_url("state_change/list"), search_hash.post_body_hash()
    end
  end
end


