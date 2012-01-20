module R8::Client
  class NodeCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :type,:id, :description, :external_ref]
    end
    desc "list","List Node groups"
    method_option "only-in-targets", :aliases => "-t", :type => :boolean
    method_option "only-in-libraries", :aliases => "-l", :type => :boolean
    def list()
      types = nil
      add_cols = []
      if options["only-in-targets"]
        types = TargetTypes
        add_cols = ["operational_status","datacenter_datacenter_id"]
      elsif options["only-in-libraries"]
        types = LibraryTypes
        add_cols = ["library_library_id"]
      else
        types = TargetTypes + LibraryTypes
      end
      search_hash = SearchHash.new()
      search_hash.cols = pretty_print_cols() + add_cols
      search_hash.filter = [:oneof, ":type", types]
      post rest_url("node/list"), search_hash.post_body_hash()
    end
    LibraryTypes = ["image"]
    TargetTypes = ["staged","instance"]

    desc "add-to-group NODE-ID NODE-GROUP-ID", "Add node to group"
    def add_to_group(node_id,node_group_id)
      post_body = {
        :node_id => node_id,
        :node_group_id => node_group_id
      }
      post rest_url("node/add_to_group"), post_body
    end
  end
end

