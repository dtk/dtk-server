module DTK; class Task; class Template
  class ActionList < Array
    r8_nested_require('action_list','config_components')
    def set_action_indexes!()
      each_with_index{|a,i|a.index = i}
      self
    end

    def find_matching_node_id(node_name)
      #teher can be multiple matches, but first match is fien since they will all agree on node_id
      if match = find_matching_action(node_name)
        unless node_id = match.node_id()
          Log.error("Unexpected that node id is nil for node name (#{node_name})")
        end
        node_id
      end
    end

    def find_matching_action(node_name,component_name_ref=nil)
      find{|a|a.match?(node_name,component_name_ref)}
    end

    def <<(el)
      super(Action.create(el))
    end
  end
end; end; end
