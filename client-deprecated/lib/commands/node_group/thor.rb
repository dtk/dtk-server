module DTK::Client
  class NodeGroupCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :type,:id, :description]
    end
    desc "list","List Node groups"
    def list()
      search_hash = SearchHash.new()
      search_hash.cols = pretty_print_cols()
      search_hash.filter = [:oneof, ":type", ["node_group_instance"]]
      post rest_url("node_group/list"), search_hash.post_body_hash()
    end

    desc "set-profile NODE-GROUP-ID TEMPLATE-NODE-ID", "Set node group's default node template"
    def set_profile(node_group_id,template_node_id)
      post_body_hash = {:node_group_id => node_group_id, :template_node_id => template_node_id}
      post rest_url("node_group/set_default_template_node"),post_body_hash
    end

    desc "add-template-node NODE-GROUP-ID", "Copy template node from library and add to node group"
    def add_template_node(node_group_id)
      post_body_hash = {:node_group_id => node_group_id}
      post rest_url("node_group/clone_and_add_template_node"),post_body_hash
    end

    desc "members NODE-GROUP-ID", "Node group members"
    def members(node_group_id)
      get rest_url("node_group/members/#{node_group_id.to_s}")
    end

    desc "create NODE-GROUP-NAME", "Create node group"
    method_option "in-target",:aliases => "-t" ,
      :type => :numeric, 
      :banner => "TARGET-ID",
      :desc => "Target (id) to create node group in"
    def create(name)
      target_id = options["in-target"]
      save_hash = {
        :parent_model_name => "target",
        :display_name => name,
        :type => "node_group_instance"
      }
      save_hash[:parent_id] = target_id if target_id
      post rest_url("node_group/save"), save_hash
    end

    desc "delete NODE-GROUP-ID", "Delete node group"
    def delete(id)
      delete_hash = {:id => id}
      post rest_url("node_group/delete"), delete_hash
    end
  end
end

