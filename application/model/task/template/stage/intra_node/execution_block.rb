module DTK; class Task; class Template
  class Stage; class IntraNode
    class ExecutionBlock < Array
      def node()
        #all the elements have same node so can just pick first
        first && first[:node]
      end
      def config_agent_type()
        #TODO: for now all  elements have same config_agent_type, so can just pick first
        first && first.config_agent_type()
      end
      def components()
        map{|a|a.hash_subset(*Component::Instance.component_list_fields)}
      end
      
      def serialization_form(opts={})
        ordered_components = map{|a|a.serialization_form(opts)}.compact
        {:ordered_components => ordered_components} unless ordered_components.empty?
      end
      def self.parse_and_reify(serialized_eb,node_name,action_list)
        ret = new()
        unless ordered_actions = serialized_eb[:ordered_components]
          ParseError.new("Ill-formed Execution block (#{serialized_eb.inspect})")
        end
        ordered_actions.each do |serialized_action|
          if serialized_action.kind_of?(String)
            component_name_ref = serialized_action
            if action = action_list.find_matching_action(node_name,component_name_ref)
              ret << action
            else
              ParseError.new("Component action ref (#{component_name_ref}) on node (#{node_name}) cannot be resolved")
            end
          else
            raise ParseError.new("Parse error for action of form (#{serialized_action.inspect})")
          end
        end
        ret
      end

      class Unordered < self
        def order(intra_node_contraints,strawman_order=nil)
          #short-cut, no ordering if singleton
          if size < 2
            return Ordered.new(self)
          end
          ret = Ordered.new()
          sorted_action_indexes = intra_node_contraints.ret_sorted_action_indexes(self)
          ndx_action_list = inject(Hash.new){|h,a|h.merge(a.index => a)}
          sorted_action_indexes.each{|index|ret << ndx_action_list[index]}
          ret
        end
      end
    
      class Ordered < self
        def initialize(array=nil)
          super()
          if array
            array.each{|el|self << el}
          end
        end
      end
    end

  end; end
end; end; end
