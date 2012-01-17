module R8::Client
  class NodeCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :type,:id, :description]
    end
    desc "list","List Node groups"
    method_option "only-in-targets", :aliases => "-t", :type => :boolean
    method_option "only-in-libraries", :aliases => "-l", :type => :boolean
    def list()
      types = ["instance","image"]
      add_cols = []
      if options["only-in-targets"]
        types = ["instance"]
        add_cols = ["datacenter_datacenter_id"]
      elsif options["only-in-libraries"]
        types = ["image"]
        add_cols = ["library_library_id"]
      end

      search_hash = SearchHash.new()
      search_hash.cols = self.class.pretty_print_cols() + add_cols
      search_hash.filter = [:oneof, ":type", types]
      post rest_url("node/list"), search_hash.post_body_hash()
    end
  end
end

