module DTK; class Task; class Template
  class ActionList < Array
    r8_nested_require('action_list','config_components')
    def set_action_indexes!()
      each_with_index{|a,i|a.index = i}
      self
    end

    def get_matching_node_id?(node_name)
      if match = find{|a|a.node_name() == node_name}
        unless node_id = match.node_id()
          Log.error("Unexpected that node id is nil for node name (#{node_name})")
        end
        node_id
      end
    end

    def <<(el)
      super(Action.create(el))
    end
  end
end; end; end
