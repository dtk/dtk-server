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

      def find_earliest_match?(action_match,action_indexes)
        each_action_with_position do |a,pos|
          if action_indexes.include?(a.index)
            action_match.action = a
            action_match.action_position = pos
            return true
          end
        end
        false
      end

      def delete_action!(action_match)
        delete_at(action_match.action_position()-1)
        :empty if empty?()
      end
       
      def splice_in_action!(action_match,insert_point)
        case insert_point
          when :end
            self << action_match.insert_action
          when :before_action_pos
            insert(action_match.action_position-1,action_match.insert_action)
          else raise Error.new("Unexpected insert_point (#{insert_point})")
        end
      end
        
      def serialization_form(opts={})
        ordered_components = map{|a|a.serialization_form(opts)}.compact
        {:ordered_components => ordered_components} unless ordered_components.empty?
      end

      #action list can be nil just for parsing
      def self.parse_and_reify(serialized_eb,node_name,action_list)
        ret = new()
        return ret unless action_list
        unless ordered_actions = serialized_eb[:ordered_components]
          raise ErrorParsing.new("Ill-formed Execution block (#{serialized_eb.inspect})")
        end
        ordered_actions.each do |serialized_action|
          if serialized_action.kind_of?(String)
            component_name_ref = serialized_action
            if action = action_list.find_matching_action(node_name,component_name_ref)
              ret << action
            else
              raise ErrorParsing.new("Component action ref (#{component_name_ref}) on node (#{node_name}) cannot be resolved")
            end
          else
            raise ErrorParsing::WrongType.new(serialized_action,String)
          end
        end
        ret
      end

     private
      def each_action_with_position(&block)
        each_with_index{|a,i|block.call(a,i+1)}
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
