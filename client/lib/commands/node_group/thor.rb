module R8::Client
  class NodeGroupCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :type,:id, :description]
    end
    desc "list","List Node groups"
    def list()
      search_hash = SearchHash.new()
      search_hash.cols = self.class.pretty_print_cols()
      search_hash.filter = [:oneof, ":type", ["node_group_instance"]]
      post rest_url("node_group/list"), search_hash.post_body_hash()
    end

    desc "create_in_target NODE-GROUP-NAME TARGET-ID", "Create node group in target"
    def create_in_target(name,target_id)
      save_hash = {
        :parent_id => target_id,
        :parent_model_name => "target",
        :display_name => name,
        :type => "node_group_instance"
      }
      post rest_url("node_group/save"), save_hash
    end

    desc "delete NODE-GROUP-ID", "Delete node group"
    def delete(id)
      delete_hash = {:id => id}
      post rest_url("node_group/delete"), delete_hash
    end
  end
end

