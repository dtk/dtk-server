module R8::Client
  class TargetCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :description, :type, :iaas_type]
    end
    desc "list","List targets"
    def list()
      search_hash = SearchHash.new()
      search_hash.cols = pretty_print_cols()
      post rest_url("target/list"), search_hash.post_body_hash()
    end
  end
end

