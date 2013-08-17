module DTK; class Task; class Template
  class ActionList < ::Array
    r8_nested_require('action_list','config_components')

    def initialize(action_list=nil)
      super()
      @action_index = Hash.new
      if action_list
        action_list.each do |a|
          unless i =  a.index
            raise Error.new("An action list passed into ActionList.new must have actions with set indexes")
          end
          @action_index[i] = a
          self << a
        end
      end
    end

    def set_action_indexes!()
      #sets both indexes on actions @action_index
      each_with_index do |a,i|
        a.index = i
        @action_index[i] = a
      end
      self
    end

    def index(i)
      @action_index[i]
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

    def select(&block)
      ret = self.class.new()
      each{|el|ret << el if block.call(el)}
      ret.set_action_indexes!()
    end

    def <<(el)
      super(el.kind_of?(Action) ? el : Action.create(el))
    end


  end
end; end; end
